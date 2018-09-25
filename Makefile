run:
	tool /home/francesco/WORKING_DIRECTORY/ a

services:
	tool /home/francesco/WORKING_DIRECTORY/ s

clean:
	rm -f manifest_files.txt
	rm -f exposed_activities_i.txt
	rm -f exposed_activities_e.txt
	rm -f exposed_activities_perm.txt
	rm -f test_activities_i.txt
	rm -f test_activities_e.txt
	rm -f exposed_services_i.txt
	rm -f exposed_services_e.txt
	rm -f exposed_services_perm.txt
	rm -f test_services_i.txt
	rm -f test_services_e.txt