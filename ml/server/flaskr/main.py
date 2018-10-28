from flask import Flask, request
from flaskr import app, db
from flaskr.models import Response, Evaluation

import uuid
import requests
from pathlib import Path
from estimator import InstaScoreEstimator

APP_ROOT = Path(app.config['PROJECT_ROOT'])
IMAGE_PATH = APP_ROOT / 'images'

model = InstaScoreEstimator()

@app.route("/")
def hello():
    r = Response()
    r.data = 'Hello, World'

    return r.json

def download_image(url, save_path):
    img_data = requests.get(url).content
    with open(save_path, 'wb') as handler:
        handler.write(img_data)

@app.route("/run", methods=['POST'])
def run():
    # request
    r = Response()
    image_url = request.args.get('image_url')
    if image_url is None:
        image_url = request.json.get('image_url')

    # image
    eval_uuid = str(uuid.uuid1())
    ext = Path(image_url).suffix
    image_path = str(IMAGE_PATH/(eval_uuid+ext))
    download_image(image_url, image_path)

    # create evaluation entry
    evaluation = Evaluation(
                    uuid=eval_uuid,
                    image_path=image_path,
                    image_url=image_url)
    db.session.add(evaluation)
    db.session.commit()

    # evaluation
    bbox, box_area, img_area, score = model.predict(image_path)

    # response
    r.data = {
        'bbox': bbox,
        'box_area': box_area,
        'img_area': img_area,
        'area_ratio': box_area/img_area,
        'score': score,
    }

    return r.json

@app.errorhandler(404)
@app.errorhandler(405)
def error_handler(error):
    r = Response('error', str(error))
    return r.json, error.code
