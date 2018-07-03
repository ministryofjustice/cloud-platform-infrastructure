#!/usr/bin/env python3

import os
from auth0.v3.authentication import GetToken
from auth0.v3.management import Auth0
from auth0.v3.authentication import users
import pprint

domain = os.getenv('auth0_domain_id', 'razvan-tests.eu.auth0.com')
non_interactive_client_id = os.getenv('auth0_client_id')
non_interactive_client_secret = os.getenv('auth0_client_secret')

get_token = GetToken(domain)
token = get_token.client_credentials(non_interactive_client_id,
    non_interactive_client_secret, 'https://{}/api/v2/'.format(domain))
mgmt_api_token = token['access_token']
a = Auth0(domain=domain, token=mgmt_api_token)

pprint.pprint(a.connections.all())
