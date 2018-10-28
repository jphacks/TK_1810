from path import Path
from PIL import Image
import cv2
import random
import pandas as pd
import pickle
import datetime


def get_filepath_list(dir_path):
    imgs = Path(dir_path).files('*.png')
    imgs += Path(dir_path).files('*.jpg')
    imgs += Path(dir_path).files('*.jpeg')
    
    return imgs


def hconcat_resize_min(im_list, interpolation=cv2.INTER_CUBIC):
    h_min = min(im.shape[0] for im in im_list)
    im_list_resize = [cv2.resize(im, (int(im.shape[1] * h_min / im.shape[0]), h_min), interpolation=interpolation)
                      for im in im_list]
    return cv2.hconcat(im_list_resize)


def create_new_dataframe(path_list):
    df = pd.DataFrame(columns=['filename', 'score', 'num_of_evaluations'])
    df['filename'] = [path.rsplit('/')[-1] for path in path_list]
    df['score'] = [0 for i in range(len(path_list))]
    df['num_of_evaluations'] = [0 for i in range(len(path_list))]
    
    return df


def evaluate_images_relative_random(path_list, random_combination_list):
    df = create_new_dataframe(path_list)
    score_list = [0 for i in range(len(path_list))]
    num_evals = [0 for i in range(len(path_list))]
    
    key_f, key_j, key_q = ord('f'), ord('j'), ord('q')
    rep_list = [key_f, key_j, key_q]
    end_flag = False
    font = cv2.FONT_HERSHEY_SIMPLEX
    
    for count, (i, j) in enumerate(random.sample(random_combination_list, len(random_combination_list))):
        s1, s2 = random.sample([i, j], 2)
        img1 = cv2.imread(path_list[s1])
        img2 = cv2.imread(path_list[s2])
        merged = hconcat_resize_min([img1, img2])
        
        cv2.namedWindow("image", cv2.WINDOW_KEEPRATIO | cv2.WINDOW_NORMAL)
        cv2.resizeWindow('image', 1200, 450)
        cv2.moveWindow('image', 100, 200)
        text_pos = (merged.shape[1] - 300, merged.shape[0] - 50)
        cv2.putText(merged, "{}/{}".format(count+1, len(random_combination_list)), text_pos, font, 1.5, (0, 0, 0), 2, cv2.LINE_AA)
        cv2.imshow('image', merged)

        key = 0
        while key not in rep_list:
            key = cv2.waitKey(0)
        cv2.destroyWindow('image')

        if key is key_f:
            score_list[s1] = score_list[s1] + 1
            num_evals[s1] = num_evals[s1] + 1
            num_evals[s2] = num_evals[s2] + 1
        elif key is key_j:
            score_list[s2] = score_list[s2] + 1
            num_evals[s1] = num_evals[s1] + 1
            num_evals[s2] = num_evals[s2] + 1
        else:
            end_flag = True
            break

        if end_flag:
            break

    df['score'] = df['score'] + score_list
    df['num_of_evaluations'] = df['num_of_evaluations'] + num_evals
    df.to_csv('./output/omelette_rice500/{}.csv'.format(datetime.datetime.today().strftime('%Y%m%d%H%M%S')))


def main_relative_random():
    print('Please enter the number of evaluate : ', end='')
    num = int(input())
    
    filepath_list = get_filepath_list('./images/omelette_rice_500/images/')
    
    try:
        with open('./pickle/start_position.pickle', 'rb') as f:
            start_pos = pickle.load(f)
    except:
        start_pos = 0
        
    with open('./pickle/rand_combination500_list.pickle', 'rb') as f:
        tmp = sorted(pickle.load(f))
        end_pos = start_pos + num
        if(end_pos > len(tmp)):
            random_combination_list = tmp[start_pos : len(tmp)] + tmp[0 : end_pos%len(tmp)]
        else:
            random_combination_list = tmp[start_pos : end_pos]
    
    evaluate_images_relative_random(filepath_list, random_combination_list)
    with open('./pickle/start_position.pickle', 'wb') as f:
        start_pos = int((start_pos + num) % (len(tmp) * 10 / 2))
        pickle.dump(start_pos, f)
        
    print('Thank you!')


if __name__=='__main__':
    main_relative_random()
