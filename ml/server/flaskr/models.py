from flaskr import db
from flask import jsonify

class Evaluation(db.Model):
    __tablename__ = 'evaluations'
    id         = db.Column(db.Integer, primary_key=True)
    uuid       = db.Column(db.String)
    image_url  = db.Column(db.String)
    image_path = db.Column(db.String)
    created_at = db.Column(db.DateTime, default=db.func.now())

    def __repr__(self):
        return '<Evaluation id={id} image_url={url!r} image_path={path!r}>'\
                .format(id=self.id, url=self.image_url, path=self.image_path)

class Response:
    def __init__(self, status='ok', message='', data=None):
        self.status  = status
        self.message = message
        self.data    = data
    
    @property
    def json(self):
        response = {}
        response['status']  = self.status
        response['message'] = self.message
        response['data']    = self.data

        return jsonify(response)

def init():
    db.drop_all()
    db.create_all()

if __name__=="__main__":
    init()
