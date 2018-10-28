import glob
import random
import os
import numpy as np

import torch

from torch.utils.data import Dataset
from PIL import Image
import torchvision.transforms as transforms

import matplotlib.pyplot as plt
import matplotlib.patches as patches

from skimage.transform import resize

from chainercv.visualizations import vis_bbox
from chainercv.links.model.ssd import random_distort
from chainercv.links.model.ssd import random_crop_with_bbox_constraints
from chainercv import transforms

class ImageFolder(Dataset):
    def __init__(self, folder_path, img_size=416):
        self.files = sorted(glob.glob('%s/*.*' % folder_path))
        self.img_shape = (img_size, img_size)

    def __getitem__(self, index):
        img_path = self.files[index % len(self.files)]
        # Extract image
        img = np.array(Image.open(img_path))
        h, w, _ = img.shape
        dim_diff = np.abs(h - w)
        # Upper (left) and lower (right) padding
        pad1, pad2 = dim_diff // 2, dim_diff - dim_diff // 2
        # Determine padding
        pad = ((pad1, pad2), (0, 0), (0, 0)) if h <= w else ((0, 0), (pad1, pad2), (0, 0))
        # Add padding
        input_img = np.pad(img, pad, 'constant', constant_values=127.5) / 255.
        # Resize and normalize
        input_img = resize(input_img, (*self.img_shape, 3), mode='reflect')
        # Channels-first
        input_img = np.transpose(input_img, (2, 0, 1))
        # As pytorch tensor
        input_img = torch.from_numpy(input_img).float()

        return img_path, input_img

    def __len__(self):
        return len(self.files)


class ListDataset(Dataset):
    def __init__(self, list_path, img_size=416):
        with open(list_path, 'r') as file:
            self.img_files = file.readlines()
        self.label_files = [path.replace('images', 'labels').replace('.png', '.txt').replace('.jpg', '.txt') for path in self.img_files]
        self.img_shape = (img_size, img_size)
        self.max_objects = 50

    def __getitem__(self, index):
        img_path = self.img_files[index % len(self.img_files)].rstrip()
        img = np.array(Image.open(img_path))
        h, w, _ = img.shape

        label_path = self.label_files[index % len(self.img_files)].rstrip()

        if not os.path.exists(label_path):
            raise Exception("the label file(.txt) is not found corresponding + " + img_path)

        labels = np.loadtxt(label_path).reshape(-1, 5)
        
        #--------------------
        #  data augmentation
        #--------------------
        lx = w * (labels[:, 1] - labels[:, 3]/2)
        ly = h * (labels[:, 2] - labels[:, 4]/2)
        bx = w * (labels[:, 1] + labels[:, 3]/2)
        by = h * (labels[:, 2] + labels[:, 4]/2)

        # convert to chainercv format: (ly, lx, by, bx)
        cv_bbox = np.stack([ly, lx, by, bx], axis=1)
        cv_labels = labels[:, 0].reshape(-1).astype(np.int)
        cv_img = img.transpose(2, 0, 1)

        # 1. Random distort
        cv_img = random_distort(cv_img)
        
        # 2. Random cropping
        cv_img, param = random_crop_with_bbox_constraints(
            cv_img, cv_bbox, min_scale=0.3, return_param=True)
        cv_bbox, param = transforms.crop_bbox(
            cv_bbox, y_slice=param['y_slice'], x_slice=param['x_slice'],
            allow_outside_center=False, return_param=True)
        cv_labels = cv_labels[param['index']]


        # 3. Random horizontal flipping
        _, _h, _w = cv_img.shape
        cv_img, params = transforms.random_flip(
            cv_img, x_random=True, return_param=True)
        cv_bbox = transforms.flip_bbox(
            cv_bbox, (_h, _w), x_flip=params['x_flip'])
        
        # update params
        img = cv_img.transpose(1, 2, 0)
        h, w, _ = img.shape

        # convert to default format: (cx, cy, w, h)
        labels = np.zeros((cv_labels.size, 5))
        labels[:, 0] = cv_labels
        labels[:, 1] = (cv_bbox[:, 3] + cv_bbox[:, 1]) / 2.0 / w # cx
        labels[:, 2] = (cv_bbox[:, 2] + cv_bbox[:, 0]) / 2.0 / h # cy
        labels[:, 3] = (cv_bbox[:, 3] - cv_bbox[:, 1]) / w       # w
        labels[:, 4] = (cv_bbox[:, 2] - cv_bbox[:, 0]) / h       # x

        #---------
        #  image
        #---------
        dim_diff = np.abs(h - w)
        # Upper (left) and lower (right) padding
        pad1, pad2 = dim_diff // 2, dim_diff - dim_diff // 2
        # Determine padding
        pad = ((pad1, pad2), (0, 0), (0, 0)) if h <= w else ((0, 0), (pad1, pad2), (0, 0))
        # Add padding
        input_img = np.pad(img, pad, 'constant', constant_values=128) / 255.
        padded_h, padded_w, _ = input_img.shape
        # Resize and normalize
        input_img = resize(input_img, (*self.img_shape, 3), mode='reflect')
        # Channels-first
        input_img = np.transpose(input_img, (2, 0, 1))
        # As pytorch tensor
        input_img = torch.from_numpy(input_img).float()

        #---------
        #  Label
        #---------
        # Extract coordinates for unpadded + unscaled image
        x1 = w * (labels[:, 1] - labels[:, 3]/2)
        y1 = h * (labels[:, 2] - labels[:, 4]/2)
        x2 = w * (labels[:, 1] + labels[:, 3]/2)
        y2 = h * (labels[:, 2] + labels[:, 4]/2)
        # Adjust for added padding
        x1 += pad[1][0]
        y1 += pad[0][0]
        x2 += pad[1][0]
        y2 += pad[0][0]
        # Calculate ratios from coordinates
        labels[:, 1] = ((x1 + x2) / 2) / padded_w
        labels[:, 2] = ((y1 + y2) / 2) / padded_h
        labels[:, 3] *= w / padded_w
        labels[:, 4] *= h / padded_h

        # Fill matrix
        filled_labels = np.zeros((self.max_objects, 5))
        if labels is not None:
            filled_labels[range(len(labels))[:self.max_objects]] = labels[:self.max_objects]
        filled_labels = torch.from_numpy(filled_labels)

        return img_path, input_img, filled_labels

    def __len__(self):
        return len(self.img_files)
