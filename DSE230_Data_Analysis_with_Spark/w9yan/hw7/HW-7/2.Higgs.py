# Name: Wen Yan
# Email: w9yan@qti.qualcomm.com
# PID: A53228033 
from pyspark import SparkContext
sc = SparkContext()
# Your program here

# coding: utf-8

# In[1]:

from pyspark.mllib.linalg import Vectors
from pyspark.mllib.regression import LabeledPoint

from string import split,strip

from pyspark.mllib.tree import GradientBoostedTrees, GradientBoostedTreesModel
from pyspark.mllib.tree import RandomForest, RandomForestModel

from pyspark.mllib.util import MLUtils

# ### Higgs data set
path='/HIGGS/HIGGS.csv'
inputRDD=sc.textFile(path)
inputRDD.first()

# Transform the text RDD into an RDD of LabeledPoints
Data=inputRDD.map(lambda line: [float(strip(x)) for x in line.split(',')]).map(lambda v: LabeledPoint(v[0], v[1:]))

# ### Reducing data size
# In order to see the effects of overfitting more clearly, we reduce the size of the data by a factor of 10

# In[6]:

Data1=Data.sample(False,0.1, seed=255).cache()
(trainingData,testData)=Data1.randomSplit([0.7,0.3], seed=255)

# Gradient Boosted Tree
errors={}
#for depth in [1,3,6,10]:
for depth in [11]:
    model=GradientBoostedTrees.trainClassifier(trainingData, categoricalFeaturesInfo={}, maxDepth=depth, numIterations=11)
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

# Random Forest
#from pyspark.mllib.tree import RandomForest, RandomForestModel
#
#errors={}
#for depth in [15]:
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
