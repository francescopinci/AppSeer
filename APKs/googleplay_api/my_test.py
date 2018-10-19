from gpapi.googleplay import GooglePlayAPI, RequestError

import sys
import argparse

ap = argparse.ArgumentParser(description='Test')
ap.add_argument('-e', '--email', dest='email', help='google username')
ap.add_argument('-p', '--password', dest='password', help='google password')

args = ap.parse_args()

server = GooglePlayAPI('en_US', 'Usa/Chicago')

# LOGIN

print('\nLogging in with email and password\n')
server.login(args.email, args.password, None, None)
gsfId = server.gsfId
authSubToken = server.authSubToken

print('\nNow trying secondary login with ac2dm token and gsfId saved\n')
# server = GooglePlayAPI('it_IT', 'Europe/Rome')
server.login(None, None, gsfId, authSubToken)

# SEARCH

apps = server.search('telegram', 34, None)

# print('\nSearch suggestion for "fir"\n')
# print(server.searchSuggest('fir'))

# print('nb_result: 34')
# print('number of results: %d' % len(apps))

print('\nFound those apps:\n')
for a in apps:
    print(a['docId'])


# DOWNLOAD
docid = apps[0]['docId']
print('\nTelegram docid is: %s\n' % docid)
print('\nAttempting to download %s\n' % docid)
fl = server.download(docid)
with open(docid + '.apk', 'wb') as apk_file:
    for chunk in fl.get('file').get('data'):
        apk_file.write(chunk)
    print('\nDownload successful\n')