# Name: Wen Yan
# Email: w9yan@qti.qualcomm.com
# PID: A53228033 
from pyspark import SparkContext
sc = SparkContext()

# coding: utf-8

# In[1]:

#import findspark
#findspark.init()
#from pyspark import SparkContext
#sc = SparkContext(master="local[4]")

from pyspark.mllib.linalg import Vectors
from pyspark.mllib.regression import LabeledPoint

from string import split,strip

from pyspark.mllib.tree import GradientBoostedTrees, GradientBoostedTreesModel
from pyspark.mllib.util import MLUtils


path='/covtype/covtype.data'
inputRDD=sc.textFile(path)
inputRDD.first()


# ### Making the problem binary
# 
# The implementation of BoostedGradientTrees in MLLib supports only binary problems. the `CovTYpe` problem has
# 7 classes. To make the problem binary we choose the `Lodgepole Pine` (label = 2.0). We therefor transform the dataset to a new dataset where the label is `1.0` is the class is `Lodgepole Pine` and is `0.0` otherwise.

Label=2.0
Data=inputRDD.map(lambda line: [float(x) for x in line.split(',')]).map(lambda V:LabeledPoint(1.0 if V[-1]==2.0 else 0.0, V[:-1]))

(trainingData,testData)=Data.randomSplit([0.7,0.3],seed=255)

# ### Gradient Boosted Trees
errors={}
#for depth in [1,3,6,10,15]:
for depth in [15]:
    model=GradientBoostedTrees.trainClassifier(trainingData, categoricalFeaturesInfo={}, maxDepth=depth, numIterations=10)
    #print model.toDebugString()
    errors[depth]={}
    dataSets={'train':trainingData,'test':testData}
    for name in dataSets.keys():  # Calculate errors on train and test sets
        data=dataSets[name]
        Predicted=model.predict(data.map(lambda x: x.features))
        LabelsAndPredictions=data.map(lambda lp: lp.label).zip(Predicted)
        Err = LabelsAndPredictions.filter(lambda (v,p):v != p).count()/float(data.count())
        errors[depth][name]=Err
    print depth,errors[depth]


# ### Random Forests
#from pyspark.mllib.tree import RandomForest, RandomForestModel
#
#errors={}
#for depth in [1,3,6,10,15,20]:
#    model = RandomForest.trainClassifier(trainingData, 7, {}, 10, featureSubsetStrategy='auto', impurity='gini', maxDepth=depth, maxBins=32, seed=None)
#
#    #print model.toDebugString()
#    errors[depth]={}
#    dataSets={'train':trainingData,'test':testData}
#    for name in dataSets.keys():  # Calculate errors on train and test sets
#        data=dataSets[name]
#        Predicted=model.predict(data.map(lambda x: x.features))
#        LabelsAndPredictions=data.map(lambda lp: lp.label).zip(Predicted)
#        Err = LabelsAndPredictions.filter(lambda (v,p):v != p).count()/float(data.count())
#        errors[depth][name]=Err
#    print depth,errors[depth]
