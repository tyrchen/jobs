generate:
	docpad generate
	@cd raw; make; cd ..

deploy:
	docpad generate
	cd out; make; cd ../..
