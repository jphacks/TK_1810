from keras.models import Model
from keras.layers import Dense, Dropout
from keras.applications.inception_resnet_v2 import InceptionResNetV2
import tensorflow as tf

graph = tf.get_default_graph()

class NimaModel():
    def __init__(self, img_size=224):
        self.img_size = img_size
        base_model = InceptionResNetV2(input_shape=(img_size, img_size, 3), include_top=False, pooling='avg', weights=None)
        x = Dropout(0.75)(base_model.output)
        x = Dense(5, activation='softmax')(x)
        self.model = Model(base_model.input, x)

    def load_weights(self, weights_path):
        self.model.load_weights(weights_path, by_name=True)

    def predict(self, img_arr):
        global graph
        with graph.as_default():
          score = self.model.predict(img_arr, batch_size=1, verbose=0)[0]
        return score 
