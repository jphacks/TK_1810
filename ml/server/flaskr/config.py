from pathlib import Path

SQLALCHEMY_DATABASE_URI = 'sqlite:///flaskr.db'
SECRET_KEY = 'secret_key'
PROJECT_ROOT = str(Path(__file__).parents[1])
