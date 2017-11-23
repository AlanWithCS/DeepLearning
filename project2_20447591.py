#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Nov 11 20:08:23 2017

@author: changing
"""

from keras.applications.resnet50 import ResNet50
from keras.preprocessing import image

from keras.applications.resnet50 import preprocess_input, decode_predictions
from keras.layers import Input, Dense, Activation, ZeroPadding2D, BatchNormalization, Flatten, Conv2D
from keras.layers import AveragePooling2D, MaxPooling2D, Dropout, GlobalMaxPooling2D, GlobalAveragePooling2D
from keras.models import Model
from keras.models import load_model
from keras import regularizers
from keras import optimizers
from keras.preprocessing.image import ImageDataGenerator
from keras.applications.inception_v3 import InceptionV3
#from keras.applications.inception_resnet_v2 import InceptionResNetV2
from keras.applications.xception import Xception
from keras.models import Sequential
from keras.models import load_model

import numpy as np
import tensorflow as tf
from PIL import Image
import re
#%%
#hyperparameters

root = "/Users/changing/Documents/我是钱智盈的文件夹！/HKUST2017-18/课程/DEEP LEARNING/Project2/data/"
model_name = "Res_Flow_5"
size = (220,220)
input_shape = (size[0],size[1],3)
classes = 5
batch_size = 16
epochs = 16

#%%
#get the train and val data
train_add = root+"train.txt"
val_add = root+"val.txt"
test_add = root+"test.txt"

    #open the train.txt and import the file paths to file_label_list
with open(train_add) as f:
    train_list = f.readlines()
    
with open(val_add) as f2:
    val_list = f2.readlines()

with open(test_add) as f3:
    test_list = f3.readlines()
    
#%%
def import_data( size = size ):
    
    print("train_list length is:", len(train_list))
    print("val_list length is :", len(val_list))
    print("test_list length is :", len(test_list))

    pattern1 = r'./flower_photos\S*.jpg'
    pattern2 = r'(\d)\s'
    
    #get the file_list that need to be trained
    train_data_list = [ re.findall(pattern1, i)[0] for i in train_list ]
    train_label = [ int( re.findall(pattern2, i)[0] ) for i in train_list ]
    #print(file_list)
    
    val_data_list = [ re.findall(pattern1, i)[0] for i in val_list ]
    val_label = [ int( re.findall(pattern2, i)[0] ) for i in val_list ]
    
    test_data_list = [ re.findall(pattern1, i)[0] for i in test_list ]
       

    print("train_data_list length is: ", len(train_data_list))
    print("train_label length is: ", len(train_label))
    
    print("val_data_list length is: ", len(val_data_list))
    print("val_label length is: ", len(val_label))

    print("test_data_list length is: ", len(test_data_list))
    
    train_label = np.array(train_label)
    #print("train_label shape is:", train_label.shape)
    val_label = np.array(val_label)
    
    #print("val_label shape is:", val_label.shape)
    
    # Convert the image to an Image object first
    # Then resize it
    # And then convert it to a ndarray
    train_data = [ np.array( (Image.open(root+i)).resize(size, Image.ANTIALIAS) ) for i in train_data_list  ]
    train_data = np.array(train_data)
    val_data = [ np.array( (Image.open(root+i)).resize(size, Image.ANTIALIAS) ) for i in val_data_list  ]
    val_data = np.array(val_data)
    
    test_data = [ np.array( (Image.open(root+i)).resize(size, Image.ANTIALIAS) ) for i in test_data_list ]
    test_data = np.array(test_data)
    #print("train_data shape is: ", train_data.shape)
    #print("val_data shape is: ", val_data.shape)
    
    return train_data, train_label, val_data, val_label, test_data
#%%
#get the train and val data
train_data, train_label, val_data, val_label, test_data = import_data()
# normalization
train_data = train_data / 255
val_data = val_data / 255
test_data = test_data / 255
# y -> one_hot encoding
tf_train_label = tf.constant(train_label)
tf_val_label = tf.constant(val_label)
sess = tf.InteractiveSession()
train_label_oh = tf.one_hot(tf_train_label,classes).eval()
val_label_oh = tf.one_hot(tf_val_label,classes).eval() 

#%%
# This is to generate the ResNet50 
# And return the model
def gen_ResNet():
    model_ResNet = ResNet50(include_top=False,
                            weights='imagenet',
                            input_shape=input_shape
                            )
    #model_ResNet.summary()
    return model_ResNet
#%%
def gen_Incep():
    model_Incep = InceptionV3(
                            include_top=False,
                            weights='imagenet',
                            input_shape=input_shape,
                            classes = classes
                            )
    return model_Incep
#%%
def my_model():
    model_ResNet = gen_Incep()
    
    top_model = Sequential()
    
    top_model.add(Flatten(input_shape=model_ResNet.output_shape[1:]))
    #top_model.add(GlobalAveragePooling2D())
    top_model.add(Dense(1024, activation='relu'))   
    top_model.add(Dense(classes, activation='softmax',name='fc_softmax'))
    
    my_model = Model(
            inputs = model_ResNet.input,
            outputs = top_model(model_ResNet.output)
                )
    
    for layer in my_model.layers[:-6]:
        layer.trainable = False
        
    return my_model

#%%
#This is to train and evaluate the model  with no data augmentation
def model_train_val(model, train_data, train_label_oh, val_data, val_label_oh, batch_size = 32, epochs = 10):
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(x=train_data, y=train_label_oh,batch_size=batch_size, epochs=epochs)
    preds = model.evaluate(x=val_data, y=val_label_oh)
    print ("Loss = " + str(preds[0]))
    print ("Test Accuracy = " + str(preds[1]))
    
    model.save(root+model_name)
#%%
#This is to train the model with data augmentation
def model_imgen_train(model):
    adam = optimizers.Adam(lr=0.001, beta_1=0.9, beta_2=0.999, epsilon=1e-08, decay=2e-4)
    rmsprop = optimizers.RMSprop(lr=0.001, rho=0.9, epsilon=1e-08, decay=1e-5)
    model.compile(optimizer=adam, loss='categorical_crossentropy', metrics=['accuracy'])
    
    train_datagen = ImageDataGenerator(
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            zoom_range=0.2,
            shear_range=0.2,
            horizontal_flip=True)  
    
    train_datagen.fit(train_data)

    train_generator =  train_datagen.flow(train_data, train_label_oh,
                                          batch_size=batch_size)
    
    model.fit_generator( 
            train_generator,
            epochs = epochs,      
            steps_per_epoch = len(train_data)/ batch_size,
            validation_data = (val_data, val_label_oh)  
            )
    return model
    
    
    
#%%
my_model = my_model()
#%%
my_model = model_imgen_train(my_model)
preds = my_model.evaluate(x=val_data, y=val_label_oh)
#%%
test_pre = my_model.predict( test_data, batch_size=None, verbose=0, steps=None)
print ("Loss = " + str(preds[0]))
print ("Test Accuracy = " + str(preds[1]))
#%%
my_model.save(root+model_name)
#%%
test_prediction = np.argmax(test_pre, axis=1)
test_prediction.tofile("test_predicts/project2_20447591_%s.csv"%model_name,sep="\n",format='%d')

    
    
    
    
    
    
    
    
    
    




































    
