# Borrowed from https://github.com/GoogleCloudPlatform/python-docs-samples/tree/8afaa783469dc099b04e33e8fc143d57e8471e7a/iap

import flask

import requests

import validate_jwt

import os

from google.auth.transport.requests import Request
from google.oauth2 import id_token

PROJECT_NUMBER = os.getenv("PROJECT_NUMBER", "")
BACKEND_SERVICE_ID = os.getenv("BACKEND_SERVICE_ID", "")
SERVICE_HOST = os.getenv("SERVICE_HOST", "UNKNOWN")
RELAY_HOST = os.getenv("RELAY_HOST", "")
CLIENT_ID = os.getenv("CLIENT_ID", "")
app = flask.Flask(__name__)


@app.route("/") 
def root():
    jwt = flask.request.headers.get("x-goog-iap-jwt-assertion")

    _, user_email, error_str = check_auth(jwt)
    
    if error_str:
        return f"Error: {error_str}"
    return f"hello {user_email} from {SERVICE_HOST} \n"

@app.route("/relay") 
def relay_indirect():
    jwt = flask.request.headers.get("x-goog-iap-jwt-assertion")
    _, user_email, error_str = check_auth(jwt)
    if error_str:
        return f"Error: {error_str}"
    open_id_connect_token = id_token.fetch_id_token(Request(), CLIENT_ID)
    headers={"Authorization": "Bearer {}".format(open_id_connect_token)}
    r = requests.get(url = RELAY_HOST, headers=headers)
    return f"Relay response for {user_email} \n {r.text}  \n"



def check_auth(jwt):
    if jwt is None:
        return "Unauthorized request.", 401
    
    expected_audience = (
        f"/projects/{PROJECT_NUMBER}/global/backendServices/{BACKEND_SERVICE_ID}"
    )

    return validate_jwt.validate_iap_jwt(
        jwt, expected_audience
    )
    

if __name__ == "__main__":
    app.run(debug=True)