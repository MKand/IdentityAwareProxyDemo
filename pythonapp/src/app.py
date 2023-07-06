# Copyright 2017 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import platform

import flask

import requests

import validate_jwt

import os

CLOUD_PROJECT_ID = os.getenv("PROJECT_ID", "abc")
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
        f"/projects/{CLOUD_PROJECT_ID}/global/backendServices/{BACKEND_SERVICE_ID}"
    )

    return validate_jwt.validate_iap_jwt(
        jwt, expected_audience
    )
    

if __name__ == "__main__":
    app.run(debug=True)