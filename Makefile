.PHONY: generate raw deploy clean

generate: raw
	docpad generate

raw:
	@cd raw; make; cd ..

deploy:
	bin/link_recent_post
	cd out; make; cd ../..

clean:
	cd raw; make clean; cd ../..
