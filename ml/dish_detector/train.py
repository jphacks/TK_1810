from __future__ import division

from models import *
from utils.utils import *
from utils.datasets import *
from utils.parse_config import *

import sys
import time
import datetime
import argparse
import copy
from pathlib import Path
import json

import torch
from torch.utils.data import DataLoader
from torchvision import datasets
from torchvision import transforms
from torch.autograd import Variable
import torch.optim as optim
import numpy as np

from tensorboardX import SummaryWriter

def train_model(model, dataloader, optimizer, writer, epoch):
    #{{{
    for batch_i, (_, imgs, targets) in enumerate(dataloader):
        imgs = Variable(imgs.type(Tensor))
        targets = Variable(targets.type(Tensor), requires_grad=False)

        optimizer.zero_grad()
        
        loss = model(imgs, targets)

        loss.backward()
        optimizer.step()
        
        print(
            "[Epoch %d, Batch %d/%d, Phase %s] [Losses: x %f, y %f, w %f, h %f, conf %f, cls %f, total %f, recall: %.5f, precision: %.5f]"
            % (
                epoch,
                batch_i,
                len(dataloader),
                'train',
                model.losses["x"],
                model.losses["y"],
                model.losses["w"],
                model.losses["h"],
                model.losses["conf"],
                model.losses["cls"],
                loss.item(),
                model.losses["recall"],
                model.losses["precision"],
            )
        )

        model.seen += imgs.size(0)

    for k in ["x", "y", "w", "h", "conf", "cls", "recall", "precision"]:
        writer.add_scalar("data/%s" % k, model.losses[k], epoch)

    return model
    #}}}

def test_model(model, dataloader, optimizer, writer, epoch, opt):
    # {{{
    num_classes = 80
    all_detections = []
    all_annotations = []

    for batch_i, (_, imgs, targets) in enumerate(dataloader):
        imgs = Variable(imgs.type(Tensor))
        targets = Variable(targets.type(Tensor), requires_grad=False)

        with torch.no_grad():
            outputs = model(imgs)
            outputs = non_max_suppression(outputs, 80, conf_thres=opt.conf_thres, nms_thres=opt.nms_thres)

        for output, annotations in zip(outputs, targets):
            annotations = annotations.cpu()
            all_detections.append([np.array([]) for _ in range(num_classes)])
            if output is not None:
                # Get predicted boxes, confidence scores and labels
                pred_boxes = output[:, :5].cpu().numpy()
                scores = output[:, 4].cpu().numpy()
                pred_labels = output[:, -1].cpu().numpy()

                # Order by confidence
                sort_i = np.argsort(scores)
                pred_labels = pred_labels[sort_i]
                pred_boxes = pred_boxes[sort_i]

                for label in range(num_classes):
                    all_detections[-1][label] = pred_boxes[pred_labels == label]

            all_annotations.append([np.array([]) for _ in range(num_classes)])
            if any(annotations[:, -1] > 0):
                
                annotation_labels = annotations[annotations[:, -1] > 0, 0].cpu().numpy()
                _annotation_boxes = annotations[annotations[:, -1] > 0, 1:]

                # Reformat to x1, y1, x2, y2 and rescale to image dimensions
                annotation_boxes = np.empty_like(_annotation_boxes)
                annotation_boxes[:, 0] = _annotation_boxes[:, 0] - _annotation_boxes[:, 2] / 2
                annotation_boxes[:, 1] = _annotation_boxes[:, 1] - _annotation_boxes[:, 3] / 2
                annotation_boxes[:, 2] = _annotation_boxes[:, 0] + _annotation_boxes[:, 2] / 2
                annotation_boxes[:, 3] = _annotation_boxes[:, 1] + _annotation_boxes[:, 3] / 2
                annotation_boxes *= opt.img_size

                for label in range(num_classes):
                    all_annotations[-1][label] = annotation_boxes[annotation_labels == label, :]

    average_precisions = {}
    for label in range(num_classes):
        true_positives = []
        scores = []
        num_annotations = 0

        for i in range(len(all_annotations)):
            detections = all_detections[i][label]
            annotations = all_annotations[i][label]

            num_annotations += annotations.shape[0]
            detected_annotations = []

            for *bbox, score in detections:
                scores.append(score)

                if annotations.shape[0] == 0:
                    true_positives.append(0)
                    continue

                overlaps = bbox_iou_numpy(np.expand_dims(bbox, axis=0), annotations)
                assigned_annotation = np.argmax(overlaps, axis=1)
                max_overlap = overlaps[0, assigned_annotation]

                if max_overlap >= opt.iou_thres and assigned_annotation not in detected_annotations:
                    true_positives.append(1)
                    detected_annotations.append(assigned_annotation)
                else:
                    true_positives.append(0)

        # no annotations -> AP for this class is 0
        if num_annotations == 0:
            average_precisions[label] = 0
            continue

        true_positives = np.array(true_positives)
        false_positives = np.ones_like(true_positives) - true_positives
        # sort by score
        indices = np.argsort(-np.array(scores))
        false_positives = false_positives[indices]
        true_positives = true_positives[indices]

        # compute false positives and true positives
        false_positives = np.cumsum(false_positives)
        true_positives = np.cumsum(true_positives)

        # compute recall and precision
        recall = true_positives / num_annotations
        precision = true_positives / np.maximum(true_positives + false_positives, np.finfo(np.float64).eps)

        # compute average precision
        average_precision = compute_ap(recall, precision)
        average_precisions[label] = average_precision

    ap = average_precisions[45]

    print(
        "[Epoch %d/%d Phase %s] [AP: %f]"
        % (
            epoch,
            opt.epochs,
            'valid',
            ap
        )
    )
    writer.add_scalar("data/ap", ap, epoch)

    return model
    # }}}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epochs", type=int, default=100,
                            help="number of epochs")
    parser.add_argument("--image_folder", type=str, default="data/mydata/images", 
                            help="path to dataset")
    parser.add_argument("--batch_size", type=int, default=8, 
                            help="size of each image batch")
    parser.add_argument("--base_model_config_path", type=str, default="config/yolov3.cfg", 
                            help="path to model config file")
    parser.add_argument("--base_model_weights_path", type=str, default="weights/yolov3.weights", 
                            help="path to weights file")
    parser.add_argument("--model_config_path", type=str, default="config/mymodel.cfg", 
                            help="path to model config file")
    parser.add_argument("--weights_path", type=str, default=None, 
                            help="path to weights file")
    parser.add_argument("--data_config_path", type=str, default="config/mydata.data", 
                            help="path to data config file")
    parser.add_argument("--class_path", type=str, default="data/coco.names", 
                            help="path to class label file")
    parser.add_argument("--conf_thres", type=float, default=0.8, 
                            help="object confidence threshold")
    parser.add_argument("--nms_thres", type=float, default=0.4, 
                            help="iou thresshold for non-maximum suppression")
    parser.add_argument("--iou_thres", type=float, default=0.5, 
                            help="iou threshold required to qualify as detected")
    parser.add_argument("--n_cpu", type=int, default=0, 
                            help="number of cpu threads to use during batch generation")
    parser.add_argument("--img_size", type=int, default=416, 
                            help="size of each image dimension")
    parser.add_argument("--checkpoint_interval", type=int, default=250, 
                            help="interval between saving model weights")
    parser.add_argument("--checkpoint_dir", type=Path, default=Path("hoge"), 
                            help="directory where model checkpoints are saved")
    parser.add_argument("--tensorboard_path", type=Path, default=Path("runs"), 
                            help="directory where tensorboard data are saved")
    parser.add_argument("--test_interval", type=int, default=50, 
                            help="test interval")
    parser.add_argument("--use_cuda", type=bool, default=True, help="whether to use cuda if available")
    parser.add_argument('--disable_finetuning', action='store_true')
    opt = parser.parse_args()
    
    # Prepare directories
    opt.checkpoint_dir.mkdir(parents=True, exist_ok=True)
    tf_path = opt.tensorboard_path/opt.checkpoint_dir.name
    tf_path.mkdir(parents=True, exist_ok=True)
    writer = SummaryWriter(str(tf_path))

    # Store options
    config = {}
    for k in vars(opt):
        v = str(getattr(opt, k))
        config[k] = v

    # Get data configuration
    classes = load_classes(opt.class_path)
    num_classes = len(classes)
    data_config = parse_data_config(opt.data_config_path)

    # Get hyper parameters
    hyperparams = parse_model_config(opt.model_config_path)[0]
    lr       = float(hyperparams['learning_rate'])
    momentum = float(hyperparams['momentum'])
    decay    = float(hyperparams['decay'])
    steps    = [int(step) for step in hyperparams['steps'].split(",")]
    scales   = [float(scale) for scale in hyperparams['scales'].split(",")]
    config['lr']       = lr
    config['momentum'] = momentum
    config['decay']    = decay
    config['steps']    = steps
    config['scales']   = scales

    # Initiate base model
    base_model = Darknet(opt.base_model_config_path)
    base_model.load_weights(opt.base_model_weights_path)

    # Prepare my model (dish detector)
    model = Darknet(opt.model_config_path)
    
    if opt.weights_path is not None:
        model_wts = torch.load(opt.weights_path)
        model.load_state_dict(model_wts)
    elif opt.disable_finetuning:
        model.apply(weights_init_normal)
    else:
        model.apply(weights_init_normal)
        base_model_params = base_model.named_parameters()
        model_params      = dict(model.named_parameters())
        for name, param in base_model_params:
            try:
                model_params[name].data.copy_(param.data)
            except:
                print("!! {} is not copied.".format(name))

    del(base_model)
    
    for k, v in config.items():
        print('  {:<25}: {}'.format(k, v))
    with open(opt.checkpoint_dir/'config.json', 'w') as f:
        json.dump(config, f)

    cuda = torch.cuda.is_available() and opt.use_cuda
    if cuda:
        model = model.cuda()

    # Get dataloader
    dataloaders = {
        k: torch.utils.data.DataLoader(
                ListDataset(data_config[k]), 
                batch_size=opt.batch_size, 
                shuffle=True, 
                num_workers=opt.n_cpu) for k in ['train', 'valid'] 
    }

    global Tensor
    Tensor = torch.cuda.FloatTensor if cuda else torch.FloatTensor

    # optimizer = torch.optim.Adam(filter(lambda p: p.requires_grad, model.parameters()))
    optimizer = torch.optim.SGD(
                    model.parameters(), 
                    lr=lr, 
                    momentum=momentum,
                    weight_decay=decay)
    scheduler = torch.optim.lr_scheduler.MultiStepLR(
                    optimizer,
                    milestones=steps,
                    gamma=scales[0])

    for epoch in range(1, opt.epochs+1):
        scheduler.step()
        phases = ['train']
        if epoch % opt.test_interval == 0:
            phases.append('valid')

        for phase in phases:
            if phase == 'train':
                model.train()
                model = train_model(model, dataloaders[phase], optimizer, writer, epoch)
                if epoch % opt.checkpoint_interval == 0:
                    model_wts = copy.deepcopy(model.state_dict())
                    torch.save(model_wts, "%s/%d.pkl" % (opt.checkpoint_dir, epoch))
            else:
                model.eval()
                model = test_model(model, dataloaders[phase], optimizer, writer, epoch, opt)

    # save model at the end of training
    model_wts = copy.deepcopy(model.state_dict())
    torch.save(model_wts, "%s/last.pkl" % opt.checkpoint_dir)

if __name__=="__main__":
    main()
