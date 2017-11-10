#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 20 13:38:02 2017
The data_roor should be modified if you want to run the model
Otherwise you cannot find the files.
@author: changing
"""

import numpy as np
import tensorflow as tf
from time import time
#from sklearn.preprocessing import normalize
#%%
#find the paths to the files
data_root = "/Users/changing/Documents/我是钱智盈的文件夹！/HKUST2017-18/课程/DEEP LEARNING/Project1/"
train_data_file = data_root+"traindata.csv"
train_label_file = data_root+"trainlabel.csv"
test_data_file = data_root+"testdata.csv"
#%%
#Here is the model_dir
model_name = "model_f_15"
model_dir = data_root+model_name

#%%
#laod data to numpy array
start_time = time()

train_data = np.genfromtxt(train_data_file,delimiter=',')

train_label = np.genfromtxt(train_label_file,delimiter=',')
train_label = np.reshape(train_label,-1)


print(str(time()-start_time)+" seconds to process the data")
test_data = np.genfromtxt( test_data_file,delimiter=',')

print("train_data shape: ", train_data.shape)
print("train_label shape: ",train_label.shape)
print("test_data  shape: ",test_data.shape)

#%%
#Hyperparameters

learning_rate = 0.001
batch_size = 128
num_steps = 20000
train_size = train_data.shape[0]
epochs = num_steps*batch_size/train_data.shape[0]
print("epochs:",str(epochs))


#%%
#Here, features are with shape (batch_size, some columns)
#While labels are with shape (batch_size,)
def model_fn( features, labels, mode):
    #在第二、三、四层使用了dropout
    first_hidden_layer = tf.layers.dense(
           features["x"], 128, activation=tf.nn.relu
           )
    
    first_dropout = tf.nn.dropout(first_hidden_layer,0.9)
    
    second_hidden_layer = tf.layers.dense(
           first_dropout, 128, activation=tf.nn.relu
           )
    second_dropout = tf.nn.dropout(second_hidden_layer,0.5)
    
    third_hidden_layer = tf.layers.dense(
           second_dropout, 128, activation=tf.nn.relu
           )
    third_dropout = tf.nn.dropout(third_hidden_layer,0.5)
    
    fourth_hidden_layer = tf.layers.dense(
           third_dropout, 64, activation=tf.nn.relu
           )
    fourth_dropout = tf.nn.dropout(fourth_hidden_layer,0.8)
    
    fifth_hidden_layer = tf.layers.dense(
           fourth_dropout, 16, activation=tf.nn.relu
           )
    output_layer = tf.layers.dense(
           fifth_hidden_layer, 1, 
           )
    #Here, the output_layer is with shape of (sample,1)
    #And we need to decrease the dimension
    output = tf.reshape(output_layer,[-1])
    
    #predict is used to give the answer and compare
    predict = tf.sigmoid(output_layer)  
    #if the results is larger than 0.5, then we can think it as 1
    predict = tf.greater(predict,0.5)
    #Change the boolean to float
    predict = tf.cast(predict, dtype=tf.float64)
    
    if mode == tf.estimator.ModeKeys.PREDICT:
        return tf.estimator.EstimatorSpec(mode=mode, predictions=predict
               )
    
    loss_op = tf.reduce_mean(
            tf.nn.sigmoid_cross_entropy_with_logits(
                    labels = labels,
                    logits = output
                    )
            )
            
    learning_rate_decay = tf.train.exponential_decay(
                      learning_rate,                # Base learning rate.
                      tf.train.get_global_step() * batch_size,  # Current index into the dataset.
                      train_size,          # Decay step.
                      0.995,                # Decay rate.
                      staircase=True)        
    
    optimizer = tf.train.AdamOptimizer(
            learning_rate = learning_rate_decay
            )
    train_op = optimizer.minimize(
            loss = loss_op,
            global_step = tf.train.get_global_step()
            )
    
    #Evaluate the accuracy ot the model
    acc = tf.metrics.accuracy(labels=labels, predictions=predict)
    true_positive = tf.metrics.true_positives(labels=labels, predictions=predict)
    false_positive = tf.metrics.false_positives(labels=labels, predictions=predict)
    false_negative = tf.metrics.false_negatives(labels=labels, predictions=predict)
    
    return tf.estimator.EstimatorSpec(
            mode = mode,
            loss = loss_op,
            train_op = train_op,
            eval_metric_ops = {
                    "Accuracy":acc,
                    "TP":true_positive,
                    "FP":false_positive,
                    "FN":false_negative
                    }
            )
    
#%%
#Build the Estimator
def build_train_eval():
    model = tf.estimator.Estimator(model_fn,model_dir=model_dir)
    print("model directory = %s" % model_dir)    
    input_fn = tf.estimator.inputs.numpy_input_fn(
            x={'x':train_data},
            y=train_label,
            batch_size=batch_size,
            num_epochs=None,
            shuffle=True)
    model.train(input_fn,steps=num_steps)
    return model
#%%
def evaluate(model,data,label):
    input_fn = tf.estimator.inputs.numpy_input_fn(
            x={'x':data},
            y=label,
            batch_size=batch_size,
            shuffle=False
            )
    e = model.evaluate(input_fn)
    
    return e
#%%
    
def print_matrix(e):
    print("Accuracy:", e["Accuracy"])
    TN = len(train_label)-e["FP"]-e["TP"]-e["FN"]
    print("Matrix: ")
    print(str(e["TP"])+" "+str(e["FP"]))
    print(str(e["FN"])+" "+str(TN))
    
#%%  
    
def get_predict(model,data):
    input_fn = tf.estimator.inputs.numpy_input_fn(
            x={'x':data},
            y=None,
            batch_size=batch_size,
            shuffle=False
            )
    e = model.predict(input_fn)
    return e

#%%
model = build_train_eval()

#%%
#to test the accuracy for the training data
e_test = evaluate(model,data=train_data,label=train_label)
print("\n------This is the result of the the train data itself-----\n")
print_matrix(e_test)
#%%
#get the result of the train_data
origin_result = get_predict(model, train_data)
#%%
result_arr = []
for i in origin_result:
    result_arr.append(i)
result_arr = np.array(result_arr)
print(result_arr.shape)

#%%
#write the result to the csv file
result_arr.tofile("train_predicts/train_pre_%s.csv"%model_name,sep="\n",format='%d')  
#%%
#get the result of the test_data
final_result = get_predict(model, test_data)
test_result_arr = []
for i in final_result:
    test_result_arr.append(i)
test_result_arr = np.array(test_result_arr)
print(test_result_arr.shape)
#%%
#write the result to the csv file
test_result_arr.tofile("test_predicts/project1_20447591_%s.csv"%model_name,sep="\n",format='%d')
    
    
    
    
    
    
    
    
    
