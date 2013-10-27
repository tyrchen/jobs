deploy:
	wintersmith build
	cd build; make; cd ../..
