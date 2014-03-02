.PHONY: generate raw deploy clean slides

generate: raw slides
	docpad generate

slides:
	cd slides;make;cd ..

raw:
	@cd raw; make; cd ..

deploy:
	bin/link_recent_post
	cd out; make; cd ../..

clean:
	cd raw; make clean; cd ../..
