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
print('\nLogging in with email and password')
server.login(args.email, args.password, None, None)
gsfId = server.gsfId
authSubToken = server.authSubToken

print('Now trying secondary login with ac2dm token and gsfId saved')
server.login(None, None, gsfId, authSubToken)

# BROWSE
categories = []
print('Browse play store categories\n')
browse = server.browse()
for b in browse:
    # print(b['name'])
    #print(b['catId'])
    categories.append(b['catId'])

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
					#print('%s' % (app['docId']))
					count = count + 1

print(app)
print(str(count))
# DOWNLOAD
#for app in applications:
	#print('\nAttempting to download %s\n' % app)
	# fl = server.download(docid)
	# with open(docid + '.apk', 'wb') as apk_file:
	#     for chunk in fl.get('file').get('data'):
	#         apk_file.write(chunk)
	#     print('\nDownload successful\n')

	# # DOWNLOAD APP NOT PURCHASED
	# # Attempting to download Nova Launcher Prime
	# # it should throw an error 'App Not Purchased'

	# print('\nAttempting to download "com.teslacoilsw.launcher.prime"\n')
	# errorThrown = False
	# try:
	#     app = server.search('nova launcher prime', 3, None)
	#     app = filter(lambda x: x['docId'] == 'com.teslacoilsw.launcher.prime', app)
	#     app = list(app)[0]
	#     fl = server.delivery(app['docId'], app['versionCode'])
	# except RequestError as e:
	#     errorThrown = True
	#     print(e)

	# if not errorThrown:
	#     print('Download of previous app should have failed')
	#     sys.exit(1)

# print("\n# of applications: " + str(count))