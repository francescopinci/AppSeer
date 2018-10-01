import re

f1 = open('./manifests.txt', mode='r');
f2 = open('./exposed_activities_i.txt', mode='w');
f3 = open('./exposed_activities_e.txt', mode='w');
f4 = open('./test_activities_i.txt', mode='w');
f5 = open('./test_activities_e.txt', mode='w');
f6 = open('./exposed_activities_perm.txt', mode='w');
f7 = open('./results.txt', mode='w');

# list of installed packages on device build
f = open('./packages.txt', mode='r');
installed_packages = f.read()
f.close()

manifests = 0;
exposed_activities_i = 0;
exposed_activities_e = 0;
exposed_activities_perm = 0;

# lists used to avoid duplicate intents
i_list = []
e_list = []
perm_list = []

line = f1.readline()
# for each AndroidManifest.xml
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
		# check if reached the end of the manifest (no activity defined)
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

	# search through all defined activities
	searchLine = f_manifest.readline()
	while searchLine:
		# the space after <activity is to avoid <activity-alias tag
		if '<activity ' not in searchLine:
			searchLine = f_manifest.readline()
			continue
		activity = ''
		permission = ''
		flag = True
		exported = False
		empty = False
		while searchLine:
			# extract activity name
			x = re.search('android:name="(.*?)"', searchLine)
			if x != None:
				activity = x.group(1)
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
			# Exposed activity
			if empty == True:
				# i already know that this activity has no intent filters declared
				# if the activity is explicitly exported, then can be started with an explicit intent
				if exported == True:
					# check if a permission was requested
					if permission != '':
						if activity not in perm_list:
							perm_list.append(activity)
							exposed_activities_perm = exposed_activities_perm + 1
							f6.write('Manifest:\t' + manifest_path + '\n')
							f6.write('Package:\t' + package + '\n')
							f6.write('App:\t\t' + application + '\n')
							f6.write('Activity:\t' + activity + '\n')
							f6.write('Permission:\t' + permission + '\n')
							f6.write('\n')
					else:
						x = re.search('^[.]', activity)
						if x!= None:
							new_activity = package + '/' + activity
						elif package in activity:
							new_activity = activity.replace(package, package + '/')
						else:
							new_activity = package + '/.' + activity

						if new_activity not in e_list:
							e_list.append(new_activity)
							exposed_activities_e = exposed_activities_e + 1;
							f3.write('Manifest:\t' + manifest_path + '\n')
							f3.write('Package:\t' + package + '\n')
							f3.write('App:\t\t' + application + '\n')
							f3.write('Activity:\t' + activity + '\n')
							f3.write('\n')
							f5.write(new_activity + '\n')
				# start to look for the next activity
				searchLine = f_manifest.readline()
				continue # to the next activity

			empty = True
			# the activity is not empty, so
			# search all intent filters for this activity (if any)
			while '</activity' not in searchLine:
				if '<intent-filter' in searchLine:
					while '</intent-filter' not in searchLine:
						if '<action' in searchLine:
							# extract action value
							x = re.search('"(.*?)"', searchLine)
							if x != None:
								action = x.group(1)
								# exclude all android.intent.action
								if 'android.intent.action' not in action:
									# at this point i'm sure this activity is exposed and contains at least one legit intent filter
									if empty == True:
										empty = False
										if permission != '':
												exposed_activities_perm = exposed_activities_perm + 1
												f6.write('Manifest:\t' + manifest_path + '\n')
												f6.write('Package:\t' + package + '\n')
												f6.write('App:\t\t' + application + '\n')
												f6.write('Activity:\t' + activity + '\n')
												f6.write('Permission:\t' + permission + '\n')
										else:
											exposed_activities_i = exposed_activities_i + 1
											f2.write('Manifest:\t' + manifest_path + '\n')
											f2.write('Package:\t' + package + '\n')
											f2.write('App:\t\t' + application + '\n')
											f2.write('Activity:\t' + activity + '\n')	
									if permission != '':
										if action not in perm_list:
											perm_list.append(action)
											f6.write('Action:\t\t' + action + '\n')
									else:
										if action not in i_list:
											i_list.append(action)
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
				# this activity has no intent filters declared
				# if the activity is explicitly exported, then can be started with an explicit intent
				if exported == True:
					# check if a permission was requested
					if permission != '':
						if activity not in perm_list:
							perm_list.append(activity)
							exposed_activities_perm = exposed_activities_perm + 1
							f6.write('Manifest:\t' + manifest_path + '\n')
							f6.write('Package:\t' + package + '\n')
							f6.write('App:\t\t' + application + '\n')
							f6.write('Activity:\t' + activity + '\n')
							f6.write('Permission:\t' + permission + '\n')
							f6.write('\n')
					else:
						x = re.search('^[.]', activity)
						if x!= None:
							new_activity = package + '/' + activity
						elif package in activity:
							new_activity = activity.replace(package, package + '/')
						else:
							new_activity = package + '/.' + activity

						if new_activity not in e_list:
							e_list.append(new_activity)							
							exposed_activities_e = exposed_activities_e + 1;
							f3.write('Manifest:\t' + manifest_path + '\n')
							f3.write('Package:\t' + package + '\n')
							f3.write('App:\t\t' + application + '\n')
							f3.write('Activity:\t' + activity + '\n')
							f3.write('\n')
							f5.write(new_activity + '\n')
		searchLine = f_manifest.readline()
	# while end	
	# next manifest
	line = f1.readline()
	f_manifest.close()
# while end

f7.write("Manifest files analyzed:\t" + str(manifests) + '\n')
f7.write("Exposed activities found:\t" + str(exposed_activities_i+exposed_activities_e+exposed_activities_perm) + '\n')
f7.write("Activities startable by implicit intents:\t" + str(exposed_activities_i) + '\n')
f7.write("Activities startable by explicit intents:\t" + str(exposed_activities_e) + '\n')
f7.write("Activities requiring permissions:\t\t" + str(exposed_activities_perm) + '\n')
print("Manifest files analyzed:\t" + str(manifests))
print("Exposed activities found:\t" + str(exposed_activities_i+exposed_activities_e+exposed_activities_perm))
print("Activities startable by implicit intents:\t" + str(exposed_activities_i))
print("Activities startable by explicit intents:\t" + str(exposed_activities_e))
print("Activities requiring permissions:\t\t" + str(exposed_activities_perm))

f7.close()
f6.close()
f5.close()
f4.close()
f3.close()
f2.close()
f1.close()