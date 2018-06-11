import math

class DataSet:
    ''' The class parsing the training/testing processed data set '''
    def __init__(self, name):
        self.docs = {}
        self.classes = {}
        self.class_docs = {}
        self.doc_class = {}
        self.vocabulary = set() 
        data_file = name + '.data'
        with open(data_file, 'r') as f:
            # doc_id word_id word_number
            for line in iter(f):
                line = line.rstrip()
                (doc_id, word_id, word_number) = line.split(' ')
                if not self.docs.has_key(doc_id): self.docs[doc_id] = {}
                self.vocabulary.add(word_id)
                self.docs[doc_id][word_id] = self.docs[doc_id].get(word_id, 0) + int(word_number)
        label_file = name + '.label'
        with open(label_file, 'r') as f:
            # label_id
            for index, label in enumerate(iter(f)):
                label = label.rstrip()
                doc_id = str(index + 1)
                if not self.class_docs.has_key(label): self.class_docs[label] = []
                self.class_docs[label].append(doc_id)
                self.doc_class[doc_id] = label
        map_file = name + '.map'
        with open(map_file, 'r') as f:
            # label_name label_id
            for line in iter(f):
                line = line.rstrip()
                (label_name, label_id) = line.split(' ')
                self.classes[label_id] = label_name
        self.total_word_number = len(self.vocabulary)

    def get_docs(self):
        return self.docs

    def get_class_docs(self):
        return self.class_docs

    def get_classes(self):
        return self.classes

    def get_vocabulary(self):
        return self.vocabulary

    def get_total_word_number(self):
        return self.total_word_number

    def get_doc_class(self, doc):
        return self.doc_class[doc]


class BernoulliBayesClassifier:
    ''' The Bernoulli Bayes classifier '''
    def __init__(self, training_data):
        self.dataset = training_data
        self.docs = self.dataset.get_docs()
        self.class_docs = self.dataset.get_class_docs()
        self.classes = self.dataset.get_classes()
        self.vocabulary = self.dataset.get_vocabulary()
        self.class_prior_probability = {}
        self.word_likelihood = {}
        self.train()
    
    def _calc_class_prior_probability(self):
        for class_id in (self.classes.keys()):
            self.class_prior_probability[class_id] = float(len(self.class_docs[class_id])) / len(self.docs)

    def train(self):
        self._calc_class_prior_probability()
        for class_id in (self.classes.keys()):
            self.word_likelihood[class_id] = self.calc_word_likelihood(class_id)

    def calc_word_likelihood(self, class_id):
        ''' probability distribution over V that models the documents of that class. '''
        likelihood = {}
        number_doc = len(self.class_docs[class_id])
        for word in self.vocabulary:
            number_word = 0
            for doc_id in self.class_docs[class_id]:
                if self.docs[doc_id].has_key(word):
                    number_word += 1
            # with add-1 smoothing
            likelihood[word] = float(number_word+1) / (number_doc + len(self.vocabulary))
        return likelihood

    def classify_doc(self, doc):
        ''' '''
        class_probability = {}
        current_max = 0
        final_class = ''
        for class_id in (self.classes.keys()):
            probability = math.log(self.class_prior_probability[class_id])
            for word in self.vocabulary:
                b = 1 if doc.has_key(word) else 0
                wl = self.word_likelihood[class_id][word]
                probability += math.log(b*wl + (1-b)*(1-wl))

            if current_max == 0 or probability > current_max:
            #if probability > current_max:
                current_max = probability
                final_class = class_id
        return final_class

class ModelEvaluation:
    ''' The class evaluates performance of model with simple accuracy rate, \
precision, recall, F1 score. '''
    def __init__(self, results, classes):
        ''' results - dictionary {key: doc_id, value: [gold label, predict label]} '''
        self.result_checks = {}
        self.classes = classes
        self.class_number = len(self.classes)
        self.class_gold = {c: 0 for c in classes}
        self.class_predict = {c: 0 for c in classes}
        self.class_match = {c: 0 for c in classes}
        for doc_id in results:
            gold, predict = results[doc_id]
            self.class_gold[gold] += 1
            self.class_predict[predict] += 1
            match = [0,1][bool(gold  == predict)]
            if match == 1: self.class_match[gold] += 1
            self.result_checks[doc_id] = match
        
    def calc_accuracy(self):
        self.accuracy = float(sum(self.result_checks.values())) / len(self.result_checks)
        return self.accuracy

    def calc_precision_recall(self):
        self.precisions = {c: float(self.class_match[c])/self.class_predict[c] for c
                           in self.classes}
        self.recalls = {c: float(self.class_match[c])/self.class_gold[c] for c
                        in self.classes}
        self.avg_precision = sum(self.precisions.values()) / self.class_number
        self.avg_recall = sum(self.recalls.values()) / self.class_number
        return [self.avg_precision, self.avg_recall]

    def calc_f1_score(self):
        try:
            self.avg_precision, self.avg_recall
        except AttributeError:
            self.calc_precision_recall()
        self.f1_score = (self.avg_precision * self.avg_recall) / (self.avg_precision + self.avg_recall)
        return self.f1_score

    def get_class_measures(self):
        return {c: [self.class_gold[c], self.class_predict[c], self.class_match[c], self.precisions[c], self.recalls[c]] for c in self.classes}

def main():
    train_data = DataSet('train')
    classifier = BernoulliBayesClassifier(train_data)
    test_data = DataSet('test')
    test_docs = test_data.get_docs()
    compare_results = {}
    for doc in test_docs:
        gold = test_data.get_doc_class(doc)
        predict = classifier.classify_doc(test_docs[doc])
        compare_results[doc] = [gold, predict]

    performance = ModelEvaluation(compare_results, train_data.get_classes())
    accuracy = performance.calc_accuracy()
    precision,recall = performance.calc_precision_recall()
    f1 = performance.calc_f1_score()

    measures = performance.get_class_measures()
    print("class, gold, predict, matched, precision, recall")
    for c in sorted(measures.keys()):
        pack = measures[c]
        print("%5s,%5d,%8d,%7d,%10.2f,%7.2f" % (c, pack[0], pack[1], pack[2], pack[3], pack[4]))
    print("performance result:")
    print("%-20s: %.2f" % ('total accuracy', accuracy))
    print("%-20s: %.2f" % ('average precision', precision))
    print("%-20s: %.2f" % ('average recall', recall))
    print("%-20s: %.2f" % ('f1 score', f1))

    with open('result.csv', 'w') as f:
        for doc in compare_results:
            f.write("%s, %s, %s\n" % (doc, compare_results[doc][0], compare_results[doc][1]))


if __name__ == '__main__':
    main()
