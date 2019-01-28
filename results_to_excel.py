def extract_data(str):
	return (str.split(':')[1])[1:].rstrip().lstrip()

f = open('results.csv', 'w')

Dict = {}
#read data.txt and store everything in the hashmap
f2 = open('./exposed_services_i.txt', mode='r')
manifest = f2.readline()
while manifest:
	
	manifest = extract_data(manifest)
	package = extract_data(f2.readline())
	app = extract_data(f2.readline())
	activity = extract_data(f2.readline())
	
	#actions extraction loop
	action = f2.readline()
	if action == '\n':
		#use activity as key
		Dict[activity] = {}
		Dict[activity][0] = manifest
		Dict[activity][1] = package
		Dict[activity][2] = app
		Dict[activity][3] = activity
	else:
		while action != '\n':
			action = extract_data(action)
			#use activity as key
			Dict[action] = {}
			Dict[action][0] = manifest
			Dict[action][1] = package
			Dict[action][2] = app
			Dict[action][3] = activity
			action = f2.readline()
	
	manifest = f2.readline()


#read key from source.txt
f1 = open('./crash_actions.txt', mode='r')
key = f1.readline()
while key:
	key = key.rstrip()
	if '/' in key:
		action = ''
		tmpKey = key.split('/')[1]
		if tmpKey not in Dict:
			key = key.replace('/', '')
		else:
			key = tmpKey
	else:
		action = key

	if key not in Dict:
		print(key + " cannot be found\n")
	else:
		if len(Dict[key][2]) == 0:
			application = Dict[key][0]
		else:
			application = Dict[key][2]

		f.write("%s,S,%s,%s\n" % (application, Dict[key][3], action))

	key = f1.readline()

f2.close()
f1.close()
f.close()
