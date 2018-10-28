import sys, os
from pathlib import Path

import cv2
import torch
from torchvision import datasets
from torch.autograd import Variable

# detector
sys.path.append(os.environ['DETECTOR_PATH'])
from models import *
from utils.utils import *
from utils.datasets import *
            
class InstaScoreEstimator:
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

    def __init__(self):
        self.model = Darknet(self.config_path, img_size=self.img_size)
        model_wts = torch.load(self.weights_path)
        self.model.load_state_dict(model_wts)
        self.model.eval()
        if torch.cuda.is_available():
            self.model = self.model.cuda()

    def detect(self, img):
        img_h, img_w, _ = img.shape

        dim_diff = np.abs(img_h - img_w)
        # Upper (left) and lower (right) padding
        pad1, pad2 = dim_diff // 2, dim_diff - dim_diff // 2
        # Determine padding
        pad = ((pad1, pad2), (0, 0), (0, 0)) if img_h <= img_w else ((0, 0), (pad1, pad2), (0, 0))
        # Add padding
        input_img = np.pad(img, pad, 'constant', constant_values=128) / 255.
        padded_h, padded_w, _ = input_img.shape
        # Resize and normalize
        input_img = resize(input_img, (*self.img_shape, 3), mode='reflect')
        # Channels-first
        input_img = np.transpose(input_img, (2, 0, 1))
        # As pytorch tensor
        input_img = torch.from_numpy(input_img).float()

        input_imgs = input_img[None]
        input_imgs = Variable(input_imgs.type(self.Tensor))
        if torch.cuda.is_available():
            input_imgs = input_imgs.cuda()

        with torch.no_grad():
            detections = self.model(input_imgs)
            detections = non_max_suppression(detections, 80, self.conf_thresh, self.nms_thres)
        
        pad_x = max(img_h - img_w, 0) * (self.img_size / max(img.shape))
        pad_y = max(img_w - img_h, 0) * (self.img_size / max(img.shape))
        unpad_h = self.img_size - pad_y
        unpad_w = self.img_size - pad_x
        
        max_size_bbox = []
        max_s = 0
        for detection in detections:
            x1, y1, x2, y2, conf, cls_conf, cls_pred = detection.cpu().numpy()[0]
            h = ((y2 - y1) / unpad_h) * img_h
            w = ((x2 - x1) / unpad_w) * img_w
            ty = ((y1 - pad_y // 2) / unpad_h) * img_h
            tx = ((x1 - pad_x // 2) / unpad_w) * img_w
            
            if int(cls_pred) == 45 and h*w > max_s and  h*w <= img_h*1.2*img_w:
                ty, tx, by, bx = max(0, ty), max(0, tx), min(img_h, ty+h), min(img_w, tx+w)
                max_size_bbox = [ty, tx, by, bx]
                max_s = (by-ty)*(bx-tx)

        return max_size_bbox, max_s

    def predict(self, img_path):
        img = cv2.imread(img_path)
        img = img[:, :, ::-1]
        h, w, c = img.shape
        img_area = h*w
        
        # run dish detector
        bbox, bbox_area = self.detect(img)
        
        # run nima

        # calculate instagrammable score
        score = 0.5
    
        return bbox, bbox_area, img_area, score
