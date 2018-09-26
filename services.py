import re

f1 = open('./manifest_files.txt', mode='r');
f2 = open('./exposed_services_i.txt', mode='w');
f3 = open('./exposed_services_e.txt', mode='w');
f4 = open('./test_services_i.txt', mode='w');
f5 = open('./test_services_e.txt', mode='w');
f6 = open('./exposed_services_perm.txt', mode='w');
f7 = open('./results.txt', mode='w');

# list of installed packages on Android Oreo stock
f = open('./packages.txt', mode='r');
installed_packages = f.read()
f.close()

manifests = 0;
exposed_services_i = 0;
exposed_services_e = 0;
exposed_services_perm = 0;

line = f1.readline()
#for each AndroidManifest.xml
while line:
	manifest_path = line.strip('\n')
	manifests = manifests + 1;
	# open the manifest file in read mode
	f_manifest = open(manifest_path, 'r')

	# extract package name and check if it is between the installed ones
	# the first part of the manifest has always the <manifest> tag which includes the 'package' attribute
	package = ''
	while True:
		searchLine = f_manifest.readline()
		if 'package=' in searchLine:
			break;
	# extract the package name
	x = re.search('package="(.*?)"', searchLine)
	package = x.group(1)
	if package not in installed_packages:
		# next manifest
		line = f1.readline()
		f_manifest.close()
		continue

	# check if the manifest actually contains an <application> declaration otherwise move to the next manifest
	skip = False
	while True:
		searchLine = f_manifest.readline()
		if not searchLine:
			skip = True
			break
		# check if reached the end of the manifest (no service defined)
		if '</manifest>' in searchLine:
			skip = True
			break
		if '<application' in searchLine:
			break

	# exit if reached the end of the manifest
	if skip:
		# next manifest
		line = f1.readline()
		f_manifest.close()
		continue

	# check if the <application> is enabled and extract the applciation name
	application = ''
	skip = False
	while True:
		if 'android:enabled="false"' in searchLine:
			skip = True
			break
		# extract application name
		x = re.search('android:name="(.*?)"', searchLine)
		if x != None:
			application = x.group(1)
		if '/>' in searchLine:
			skip = True
			break
		if '>' in searchLine:
			break
		searchLine = f_manifest.readline()
	if skip:
		# next manifest
		line = f1.readline()
		f_manifest.close()
		continue

	# search through all defined services
	searchLine = f_manifest.readline()
	while searchLine:
		# 
		if '<service ' not in searchLine:
			searchLine = f_manifest.readline()
			continue
		service = ''
		permission = ''
		flag = True
		exported = False
		empty = False
		while searchLine:
			# extract service name
			x = re.search('android:name="(.*?)"', searchLine)
			if x != None:
				service = x.group(1)
			# check if a permission is needed
			x = re.search('android:permission="(.*?)"', searchLine)
			if x != None:
				permission = x.group(1)
				#flag = False
				#print(searchLine.strip('\n'))
				#break
			# check if it's enabled
			if 'android:enabled="false"' in searchLine:
				flag = False
				break
			if 'android:exported="false"' in searchLine:
				flag = False
				break
			if 'android:exported="true"' in searchLine:
				exported = True
			if '/>' in searchLine:
				empty = True
				break
			if '>' in searchLine:
				break
			searchLine = f_manifest.readline()
		# while end

		if flag == True:
			# Exposed service
			if empty == True:
				# i already know that this service has no intent filters declared
				# if the service is explicitly exported, then can be started with an explicit intent
				if exported == True:
					# check if a permission was requested
					if permission != '':
						exposed_services_perm = exposed_services_perm + 1
						f6.write('Manifest:\t' + manifest_path + '\n')
						f6.write('Package:\t' + package + '\n')
						f6.write('App:\t\t' + application + '\n')
						f6.write('Service:\t' + service + '\n')
						f6.write('Permission:\t' + permission + '\n')
						f6.write('\n')
					else:
						exposed_services_e = exposed_services_e + 1;
						f3.write('Manifest:\t' + manifest_path + '\n')
						f3.write('Package:\t' + package + '\n')
						f3.write('App:\t\t' + application + '\n')
						f3.write('Service:\t' + service + '\n')
						x = re.search('^[.]', service)
						if x!= None:
							f5.write(package + '/' + service + '\n')
						elif package in service:
							new_service = service.replace(package, package + '/')
							f5.write(new_service + '\n')
						else:
							f5.write(package + '/.' + service + '\n')
						f3.write('\n')
				# start to look for the next service
				searchLine = f_manifest.readline()
				continue # to the next service

			empty = True
			# the service is not empty, so
			# search all intent filters for this service (if any)
			while '</service' not in searchLine:
				if '<intent-filter' in searchLine:
					while '</intent-filter' not in searchLine:
						if '<action' in searchLine:
							# extract action value
							x = re.search('"(.*?)"', searchLine)
							if x != None:
								action = x.group(1)
								# exclude all android.intent.action
								if 'android.intent.action' not in action:
									# at this point i'm sure this service is exposed and contains at least one legit intent filter
									if empty == True:
										empty = False
										if permission != '':
											exposed_services_perm = exposed_services_perm + 1
											f6.write('Manifest:\t' + manifest_path + '\n')
											f6.write('Package:\t' + package + '\n')
											f6.write('App:\t\t' + application + '\n')
											f6.write('Service:\t' + service + '\n')
											f6.write('Permission:\t' + permission + '\n')
										else:
											exposed_services_i = exposed_services_i + 1
											f2.write('Manifest:\t' + manifest_path + '\n')
											f2.write('Package:\t' + package + '\n')
											f2.write('App:\t\t' + application + '\n')
											f2.write('Service:\t' + service + '\n')	
									if permission != '':
										f6.write('Action:\t\t' + action + '\n')
									else:
										f2.write('Action:\t\t' + action + '\n')
										f4.write(action + '\n')
						searchLine = f_manifest.readline()
					# while end
				searchLine = f_manifest.readline()
			# while end
			if empty == False:
				if permission != '':
					f6.write('\n')
				else:
					f2.write('\n')

			if empty == True:
				# this service has no intent filters declared
				# if the service is explicitly exported, then can be started with an explicit intent
				if exported == True:
					# check if a permission was requested
					if permission != '':
						exposed_services_perm = exposed_services_perm + 1
						f6.write('Manifest:\t' + manifest_path + '\n')
						f6.write('Package:\t' + package + '\n')
						f6.write('App:\t\t' + application + '\n')
						f6.write('Service:\t' + service + '\n')
						f6.write('Permission:\t' + permission + '\n')
						f6.write('\n')
					else:
						exposed_services_e = exposed_services_e + 1;
						f3.write('Manifest:\t' + manifest_path + '\n')
						f3.write('Package:\t' + package + '\n')
						f3.write('App:\t\t' + application + '\n')
						f3.write('Service:\t' + service + '\n')
						x = re.search('^[.]', service)
						if x!= None:
							f5.write(package + '/' + service + '\n')
						elif package in service:
							new_service = service.replace(package, package + '/')
							f5.write(new_service + '\n')
						else:
							f5.write(package + '/.' + service + '\n')
						f3.write('\n')
		searchLine = f_manifest.readline()
	# while end	
	# next manifest
	line = f1.readline()
	f_manifest.close()
# while end

f7.write("Manifest files analyzed:\t" + str(manifests) + '\n')
f7.write("Exposed services found:\t" + str(exposed_services_i+exposed_services_e+exposed_services_perm) + '\n')
f7.write("Services startable by implicit intents:\t" + str(exposed_services_i) + '\n')
f7.write("Services startable by explicit intents:\t" + str(exposed_services_e) + '\n')
f7.write("Services requiring permissions:\t\t" + str(exposed_services_perm + '\n'))
print("Manifest files analyzed:\t" + str(manifests))
print("Exposed services found:\t" + str(exposed_services_i+exposed_services_e+exposed_services_perm))
print("Services startable by implicit intents:\t" + str(exposed_services_i))
print("Services startable by explicit intents:\t" + str(exposed_services_e))
print("Services requiring permissions:\t\t" + str(exposed_services_perm))

f7.close()
f6.close()
f5.close()
f4.close()
f3.close()
f2.close()
f1.close()