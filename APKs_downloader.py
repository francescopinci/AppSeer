import sys
import argparse

sys.path.append('/home/francesco/Desktop/Thesis/tool/googleplay-api')

from gpapi.googleplay import GooglePlayAPI, RequestError

ap = argparse.ArgumentParser(description='Test')
ap.add_argument('-e', '--email', dest='email', help='google username')
ap.add_argument('-p', '--password', dest='password', help='google password')

args = ap.parse_args()

# server = GooglePlayAPI('it_IT', 'Europe/Rome')
server = GooglePlayAPI('en_US', 'Usa/Chicago')

# LOGIN
print('\nLogging in with email and password\n')
server.login(args.email, args.password, None, None)
gsfId = server.gsfId
authSubToken = server.authSubToken

print('\nNow trying secondary login with ac2dm token and gsfId saved\n')
server.login(None, None, gsfId, authSubToken)

# BROWSE
categories = []
print('\nBrowse play store categories\n')
browse = server.browse()
for b in browse:
    # print(b['name'])
    #print(b['catId'])
    categories.append(b['catId'])

count = 0
for c in categories:
	# print('\nCATEGORY: %s\n' % (c))
	browseCategory = server.browse(c)
	for sc in browseCategory:
		# print('Subcategory: %s' % (sc['docid']))
		# print('################################################')
		for app in sc['apps']:
			print('%s' % (app['docId']))
			count = count + 1

# print("\n# of applications: " + str(count))