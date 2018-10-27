import argparse
import re
import json
from pathlib import Path
from time import sleep
from tqdm import tqdm
import traceback
import requests

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException

parser = argparse.ArgumentParser()
parser.add_argument('--n_scrape', '-n', type=int, default=100,
                    help='num scraping posts')
parser.add_argument('--tag', '-t', default='ラーメン',
                    help='post tag')
parser.add_argument('--save_dir', '-o', default='scraped_data',
                    help='save directory')
parser.add_argument('--skip', '-s', type=int,
                    help='num posts to skip (FYI posts are ordered in newer on instgaram)')
parser.add_argument('--resume', '-r', action='store_true',
                    help='resume scraping (automatically overwrite <--savedir>/data.json)')

args = parser.parse_args()

def to_int(s):
    s = s.replace(',', '')
    if 'k' in s:
        s = s.replace('k', '')
        n = int(float(s) * 1000)
    else:
        n = int(s)

    return n

def extract_id(base_elem):
    # m = pattern.match(driver.current_url)
    link_elem = base_elem.find_element_by_css_selector("a.c-Yi7")
    url = link_elem.get_attribute("href")
    pattern = re.compile(r'https://www.instagram.com/p/([-/:-@\_~%0-9a-zA-Z]+)/')
    m = pattern.match(url)
    post_id = m.group(1)
    
    return post_id

def extract_image_urls(base_elem):
    img_elem = base_elem.find_element_by_css_selector('.KL4Bh img')
    srcset = img_elem.get_attribute('srcset')
    img_urls = {}
    for src in srcset.split(","):
        url, size = src.split(" ")
        img_urls[size] = url

    return img_urls

def extract_desc(base_elem):
    img_elem = base_elem.find_element_by_css_selector('.KL4Bh img')
    desc = img_elem.get_attribute('alt')

    return desc

def extract_user(base_elem):
    user_elem = base_elem.find_element_by_css_selector('.e1e1d>a')
    user_name = user_elem.get_attribute('title')
    user_page = user_elem.get_attribute('href')
 
    return {
        'name': user_name,
        'page': user_page,
    }

def extract_user_detail(driver, page):
    main_tab = driver.current_window_handle
    driver.execute_script("window.open('{}');".format(page)) # open in a new tab
    driver.implicitly_wait(1)
    new_tab = [tab for tab in driver.window_handles if tab != main_tab][0]
    driver.switch_to.window(new_tab) # switch to the new tab
    user_statuses = driver.find_elements_by_css_selector('a.-nal3')

    n_posts = to_int(user_statuses[0].find_element_by_css_selector('.g47SY').text)
    n_followers = to_int(user_statuses[1].find_element_by_css_selector('.g47SY').text)
    n_follows = to_int(user_statuses[2].find_element_by_css_selector('.g47SY').text)

    driver.close() # close tab
    driver.switch_to.window(main_tab) # switch back to main tab

    return {
        'n_posts': n_posts,
        'n_follows': n_follows,
        'n_followers':n_followers
    }

def extract_like(base_elem):
    try:
        like_elem = base_elem.find_element_by_css_selector('.zV_Nj>span')
        like = to_int(like_elem.text)
    except NoSuchElementException:
        like = 0

    return like

def extract_store(base_elem):
    try:
        gps_elem = base_elem.find_element_by_css_selector('a.O4GlU')
        store_name = gps_elem.text
        store_loc_page = gps_elem.get_attribute("href")
    except NoSuchElementException:
        store_name = store_loc_page = None

    return {
        'name': store_name,
        'page': store_loc_page
    }

def extract_post_time(base_elem):
    time_elem = base_elem.find_element_by_css_selector('.c-Yi7 time')
    time_text = time_elem.get_attribute("datetime")

    return time_text

def save_data(data, path):
    f = open(str(path), 'w')
    json.dump(data, f, ensure_ascii=False, indent=4, \
                       sort_keys=True, separators=(',', ': '))
    f.close()

def download_image(url, save_path):
    img_data = requests.get(url).content
    with open(save_path, 'wb') as handler:
        handler.write(img_data)

def go_next_item(base_elem, t_sleep=None):
     # tansit next item
     right_allow_button = base_elem.find_element_by_css_selector('a.coreSpriteRightPaginationArrow')
     right_allow_button.click()
     if t_sleep is not None:
         sleep(t_sleep)

def main():
    # setting
    save_dir = Path(args.save_dir)
    images_path = save_dir / 'images'
    images_path.mkdir(parents=True, exist_ok=True)
    json_path = save_dir / 'data.json'

    url = "https://www.instagram.com/explore/tags/" + args.tag
    n_scrape = args.n_scrape
    t_sleep = 2
    snapshot_interval = 10

    chrome_options = webdriver.ChromeOptions()
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1')

    # resume
    ids, data = [], []
    if args.resume and json_path.exists():
        with open(str(json_path)) as f:
            data = json.load(f)
        ids = [d['id'] for d in data]

    # start
    driver = webdriver.Chrome(chrome_options=chrome_options)
    driver.implicitly_wait(2)
    driver.get(url)

    # skip posts
    if args.skip is not None:
        loaded_posts = set()
        n = 0
        with tqdm(total=args.skip, ) as pbbar:
            pbbar.set_description('skipping...')
            while n < args.skip:
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                sleep(2)

                elems = driver.find_elements_by_css_selector('.v1Nh3.kIKUG._bz0w > a')
                for e in elems:
                    loaded_posts.add(e.get_attribute('href'))

                pbbar.update(len(loaded_posts) - n)
                n = len(loaded_posts)

    # first of all, open popup element
    elem = driver.find_elements_by_css_selector('.v1Nh3.kIKUG._bz0w')[-1]
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
    elem.click()
    popup_elem = driver.find_element_by_css_selector("._2dDPU.vCf6V")
    driver.implicitly_wait(2)

    # iterate post items on popup window, scrape it
    print('scraping...')
    for i in tqdm(range(1, n_scrape+1)):
        _data = {}
        
        # extract data
        try:
            post_id = extract_id(popup_elem)
            if post_id in ids:
                continue
            ids.append(post_id)

            _data['id']          = post_id
            _data['image_urls']  = extract_image_urls(popup_elem)
            # _data['description'] = extract_desc(popup_elem)
            # _data['user']        = extract_user(popup_elem)
            # _data['n_likes']     = extract_like(popup_elem)
            # _data['store']       = extract_store(popup_elem)
            # _data['posted_at']   = extract_post_time(popup_elem)
            
            # user_detail = extract_user_detail(driver, _data['user']['page'])
            # _data['user'].update(user_detail)

            # download image
            biggest_size = list(_data['image_urls'].keys())[-1]
            url = _data['image_urls'][biggest_size]
            image_path = images_path / "{}.jpg".format(_data['id'])
            download_image(url, image_path)
            _data['image_urls'].update({'local': str(image_path)})

            data.append(_data)
            
            # snapshot
            if i%snapshot_interval == 0:
                save_data(data, json_path)

        except NoSuchElementException:
            traceback.print_exc()
            continue

        finally:
            # tansit next item
            go_next_item(popup_elem)

            # polite sleep :)
            sleep(t_sleep)

    save_data(data, json_path)

if __name__ == "__main__":
    main()
