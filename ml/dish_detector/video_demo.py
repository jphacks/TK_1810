import argparse
import uuid
import shutil
from pathlib import Path
import subprocess as sp
from tqdm import tqdm

import torch
import cv2
import numpy as np
from moviepy.editor import VideoFileClip

from models import Darknet

parser = argparse.ArgumentParser()
parser.add_argument("input", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--config", type=Path, default=Path("config/mymodel.cfg"))
parser.add_argument("--weight", type=Path, default=Path("result/normal_finetuning_aug_full_strong/35.pkl"))
parser.add_argument("--conf_thresh", type=float, default=0.7)
parser.add_argument("--nms_thresh", type=float, default=0.4)
args = parser.parse_args()

def read_video(path):
    cap = cv2.VideoCapture(str(path))

    info = {
            'width':  int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
            'height': int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)),
            'fps':    int(cap.get(cv2.CAP_PROP_FPS))
            }
    
    video = []
    while(True):
        ret, img = cap.read()
        if ret == True:
            video.append(img)
        else:
            break
    cap.release()
    
    return np.asarray(video), info

def write_video(path, video, info):
    frame, height, width, ch = video.shape
    fourcc = cv2.VideoWriter_fourcc(*'XVID')

    writer = cv2.VideoWriter(str(path), fourcc, info['fps'], (width, height))
    for i in range(frame):
        writer.write(video[i])
    writer.release()

def main():
    # model
    model = Darknet(str(args.config), img_size=416)
    model_wts = torch.load(str(args.weight), map_location='cpu')
    model.load_state_dict(model_wts)
    if torch.cuda.is_available():
        print('gpu: available')
        model = model.cuda()
    else:
        print('gpu: not available')

    # read video
    print(">> reading video...")
    video, info = read_video(args.input)
    video = video[:,:,:,::-1]
    print("  shape:", video.shape)
    print("  info: ", info)
    
    # forward
    print(">> predicting...")
    imgs, bboxes, ss, labels = [], [], [], []
    for i in tqdm(range(0, len(video))):
        img = video[i]

        bbox, max_s = model.predict(img, args.conf_thresh, args.nms_thresh)
        
        imgs.append(img)
        ss.append(max_s)
        if len(bbox) != 0:
            bboxes.append([bbox])
            labels.append([0])
        else:
            bboxes.append([])
            labels.append([])

    # draw bbox
    imgs = np.asarray(imgs)
    # imgs = imgs[:,:,::-1]
    for i in tqdm(range(len(imgs))):
        if len(bboxes[i]) != 0:
            ty, tx, by, bx = [int(n) for n in bboxes[i][0]]
            cv2.rectangle(imgs[i], (tx, ty), (bx, by), (255, 0, 0), 3)

    # save as video
    print(">> saving video...")
    imgs = imgs[:,:,:,::-1]
    write_video(args.output, imgs, info)

if __name__ == "__main__":
    main()
