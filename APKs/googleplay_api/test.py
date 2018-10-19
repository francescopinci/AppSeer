from gpapi.googleplay import GooglePlayAPI, RequestError

import sys
import argparse

ap = argparse.ArgumentParser(description='Test')
ap.add_argument('-e', '--email', dest='email', help='google username')
ap.add_argument('-p', '--password', dest='password', help='google password')

args = ap.parse_args()

server = GooglePlayAPI('en_EN', 'Usa/Chicago')

# LOGIN

print('\nLogging in with email and password\n')
server.login(args.email, args.password, None, None)
gsfId = server.gsfId
authSubToken = server.authSubToken