# Borrowed from https://github.com/GoogleCloudPlatform/python-docs-samples/tree/8afaa783469dc099b04e33e8fc143d57e8471e7a/iap

import platform

import flask

import requests

import validate_jwt

import os

PROJECT_NUMBER = os.getenv("PROJECT_NUMBER", "123")
BACKEND_SERVICE_ID = os.getenv("BACKEND_SERVICE_ID", "abc")
SERVICE_HOST = os.getenv("SERVICE_HOST", "UNKNOWN")
PROXY_HOST = os.getenv("PROXY_HOST", "http://localhost:5000")

app = flask.Flask(__name__)


@app.route("/") 
def root():
    jwt = flask.request.headers.get("x-goog-iap-jwt-assertion")

    _, user_email, error_str = check_auth(jwt)
    
    if error_str:
        return f"Error: {error_str}"
    return f"hello {user_email} from {SERVICE_HOST} {platform.node()} \n"

@app.route("/proxy") 
def helloproxy():
    jwt = flask.request.headers.get("x-goog-iap-jwt-assertion")

    _, user_email, error_str = check_auth(jwt)

    if error_str:
        return f"Error: {error_str}"
    
    r = requests.get(url = PROXY_HOST)
    return f"Proxied response for {user_email} : {r.text}  \n"


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