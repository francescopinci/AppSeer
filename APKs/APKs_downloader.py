import sys
import argparse
from pathlib import Path

from googleplay_api.gpapi.googleplay import GooglePlayAPI, RequestError, LoginError

ap = argparse.ArgumentParser(description='Test')
ap.add_argument('-e', '--email', dest='email', help='google username')
ap.add_argument('-p', '--password', dest='password', help='google password')

args = ap.parse_args()

# server = GooglePlayAPI('it_IT', 'Europe/Rome')
server = GooglePlayAPI('en_US', 'Usa/Chicago')

# LOGIN
try:
	print('\nLogging in with email and password')
	server.login(args.email, args.password, None, None)
	gsfId = server.gsfId
	authSubToken = server.authSubToken

	print('Now trying secondary login with ac2dm token and gsfId saved\n')
	server.login(None, None, gsfId, authSubToken)
except LoginError as e:
	print(e + '\n')

file = 'applications.txt'
path = Path(file)
if not path.exists():
	# BROWSE CATEGORIES
	categories = []
	print('Browsing play store categories')
	browse = server.browse()
	for b in browse:
	    categories.append(b['catId'])

	f = open(file, mode='w');
	applications = []
	count = 0
	for c in categories:
		#print('\nCATEGORY: %s\n' % (c))
		browseCategory = server.browse(c)
		for sc in browseCategory:
			if "paid" not in sc['docid']:
				#print('Subcategory: %s' % (sc['docid']))
				#print('################################################')
				for app in sc['apps']:
					if "00,000" in app['numDownloads']:
						applications.append(app['docId'])
						f.write(app['docId'] + '\n')
						count = count + 1
	f.close()
	print("Count = ", str(count))

# DOWNLOAD
folder = '/media/francesco/FRANCESCO 2/APKs/'
f = open(file, mode='r');
app = f.readline()
while app:
	app = app.strip('\n')
	print('Attempting to download %s' % app)
	try:
		fl = server.download(app)
		with open(folder + app + '.apk', 'wb') as apk_file:
			for chunk in fl.get('file').get('data'):
				apk_file.write(chunk)
			print('Download successful\n')
	except RequestError as e:
		print(str(e) + '\n')
	app = f.readline()
	