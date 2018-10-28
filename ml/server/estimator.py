import sys, os
from pathlib import Path

import cv2
import numpy as np
import torch
from torchvision import datasets
from torch.autograd import Variable
from keras.applications.inception_resnet_v2 import preprocess_input
from keras.preprocessing.image import load_img, img_to_array
import tensorflow as tf

# detector
sys.path.append(os.environ['DETECTOR_PATH'])
from models import *
from utils.utils import *
from utils.datasets import *

# nima
sys.path.append(os.environ['REGRESSOR_PATH'])
from nima_models import NimaModel
            
class InstaScoreEstimator:
    # food detector
    detector_path = Path(os.environ['DETECTOR_PATH'])
    config_path = detector_path / "config/mymodel.cfg"
    weights_path = detector_path / "result/normal_finetuning_aug_full_strong/35.pkl"
    img_size = 416
    img_shape= (img_size, img_size)
    class_path = detector_path / "data/coco.names"
    conf_thresh = 0.7
    nms_thres = 0.4

    classes = load_classes(class_path)
    Tensor = torch.FloatTensor

    # nima
    regressor_path = Path(os.environ['REGRESSOR_PATH'])
    nima_weight_path = regressor_path / 'weights/inception_weights.h5'
    nima_img_size = 224

    def __init__(self):
        # food detector
        self.detector = Darknet(self.config_path, img_size=self.img_size)
        model_wts = torch.load(self.weights_path)
        self.detector.load_state_dict(model_wts)
        self.detector.eval()
        if torch.cuda.is_available():
            self.detector = self.detector.cuda()

        # nima
        self.regressor = NimaModel(img_size=self.nima_img_size)
        self.regressor.load_weights(self.nima_weight_path)


    def predict(self, img_path):
        img = cv2.imread(img_path)
        img = img[:, :, ::-1]
        h, w, c = img.shape
        img_area = h*w
        
        # run dish detector
        bbox, bbox_area = self.detector.predict(img, self.conf_thresh, self.nms_thres)
        
        # run nima
        img = load_img(img_path, target_size=(224, 224))
        img_arr = img_to_array(img)
        img_arr = np.expand_dims(img_arr, axis=0)
        img_arr = preprocess_input(img_arr)
        instagenic_scores = self.regressor.predict(img_arr)

        # calculate instagrammable score
        score = np.argmax(instagenic_scores) + 1.
        score /= 5.
    
        return bbox, bbox_area, img_area, score
