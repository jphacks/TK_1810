import os
import numpy as np
import pickle

from keras.models import Model
from keras.layers import Dense, Dropout
from keras.applications.inception_resnet_v2 import InceptionResNetV2
from keras.applications.inception_resnet_v2 import preprocess_input
from keras.optimizers import Adam
from keras import backend as K
from keras.preprocessing.image import load_img, img_to_array
import tensorflow as tf

with open('./pickle/file_list.pickle', 'rb') as f:
    files = pickle.load(f)
with open('./pickle/score_list.pickle', 'rb') as f:
    train_scores = pickle.load(f)

base_image_path = '../images/omelette_rice_500/images/'

X = []
for file in files:
    img = load_img(base_image_path+file, target_size=(224, 224))
    tmp = img_to_array(img)
    X.append(tmp)
    
X = preprocess_input(np.array(X))
y = train_scores

X_train = X[:-50]
y_train = y[:-50]
X_test = X[-50:]
y_test = y[-50:]

image_size = 224
base_model = InceptionResNetV2(input_shape=(image_size, image_size, 3), include_top=False, pooling='avg')
x = Dropout(0.75)(base_model.output)
x = Dense(5, activation='softmax')(x)
model = Model(base_model.input, x)

optimizer = Adam(1e-4)
model.compile(optimizer, loss='categorical_crossentropy')
model.load_weights('./weights/inception_resnet_weights_origin.h5', by_name=True)

batch_size = 50
epochs = 30

model.fit(X_train, y_train,
          batch_size=batch_size,
          epochs=epochs)
          validation_data=(X_test, y_test))

def predict(img_path):
    img = load_img(img_path, target_size=(224, 224))
    x = img_to_array(img)
    x = np.expand_dims(x, axis=0)
    x = preprocess_input(x)

    scores = model.predict(x, batch_size=1, verbose=0)[0]
    
    return scores


for i, filename in enumerate(files[-50:]):
    print(filename.rsplit('/')[-1])
    print(np.argmax(predict('../images/omelette_rice_500/images/'+filename)) + 1, end=' : ')
    print(y[i].argmax()+1)
    
import pdb; pdb.set_trace()