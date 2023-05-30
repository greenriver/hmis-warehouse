#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This is an example "local" configuration file. In order to set/override config
# options that ONLY apply to your local environment, simply copy/rename this file
# to docker/pythonpath/superset_config_docker.py
# It ends up being imported by docker/superset_config.py which is loaded by
# superset/config.py
#

import os

SQLALCHEMY_DATABASE_URI = "postgres://postgres:postgres@db/superset"
SQLALCHEMY_ECHO = True
SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]

from flask_appbuilder.security.manager import AUTH_OAUTH

print("Initializing oauth configuration")

# # Set the authentication type to OAuth
AUTH_TYPE = AUTH_OAUTH
OAUTH_PROVIDERS = [
    {   'name': 'WarehouseSSO',
        'token_key': 'access_token', # Name of the token in the response of access_token_url
        'icon': 'fa-address-card',   # Icon for the provider
        'remote_app': {
            'client_id': os.environ['SUPERSET_OAUTH_CLIENT_ID'], # Client Id (Identify Superset application)
            'client_secret': os.environ['SUPERSET_OAUTH_CLIENT_SECRET'], # Secret for this Client Id (Identify Superset application)
            # 'client_kwargs': {
            #     'scope': 'Public'               # Scope for the Authorization
            # },
            'access_token_method': 'POST',    # HTTP Method to call access_token_url
            'access_token_params': {        # Additional parameters for calls to access_token_url
                'client_id': os.environ['SUPERSET_OAUTH_CLIENT_ID']
            },
            # 'access_token_headers':{    # Additional headers for calls to access_token_url
            #     'Authorization': 'Basic Base64EncodedClientIdAndSecret'
            # },
            'api_base_url': os.environ['SUPERSET_OAUTH_API_BASE_URL'],
            'access_token_url': os.environ['SUPERSET_OAUTH_ACCESS_TOKEN_URL'],
            'authorize_url': os.environ['SUPERSET_OAUTH_AUTHORIZE_URL']
        }
    }
]

print("Done with oauth configuration")

# # Will allow user self registration, allowing to create Flask users from Authorized User
# AUTH_USER_REGISTRATION = True

# # The default user self registration role
# AUTH_USER_REGISTRATION_ROLE = "Public"
