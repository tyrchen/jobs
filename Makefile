generate:
	docpad generate
	@cd raw; make; cd ..

deploy:
	cd out; make; cd ../..

clean:
	cd raw; make clean; cd ../..
