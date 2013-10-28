CHECK=\033[32m✔\033[39m
DONE="\n${CHECK} Done.\n"
ECHO=echo
ROOT=assets

CSS_COMPRESSOR=lessc
JS_COMPRESSOR=yuicompressor
SYNC=rsync
CAT=cat
RM=rm

CSS_PATH=$(ROOT)/less
CSS_SOURCE=$(CSS_PATH)/app.less

JS_PATH=$(ROOT)/scripts
JS_PLUGIN_PATH=$(JS_PATH)/plugins
JS_SOURCE=$(JS_PLUGIN_PATH)/jquery.js $(JS_PLUGIN_PATH)/bootstrap.min.js $(JS_PLUGIN_PATH)/jquery.visible.min.js $(JS_PLUGIN_PATH)/jquery.isotope.min.js $(JS_PLUGIN_PATH)/jquery.knob.js $(JS_PLUGIN_PATH)/jquery.scrollUp.min.js $(JS_PLUGIN_PATH)/highlight.pack.js $(JS_PATH)/application.js

CSS_TARGET=$(ROOT)/css/app.min.css
JS_TARGET=$(ROOT)/js/app.min.js

SYNC_TARGET=../out


sync: $(CSS_TARGET) $(JS_TARGET)
	$(SYNC) -au --exclude $(CSS_PATH) --exclude $(JS_PATH) --exclude Makefile . $(SYNC_TARGET)
	@$(ECHO) $(DONE)

$(CSS_TARGET):
	$(CSS_COMPRESSOR) $(CSS_SOURCE) --yui-compress  > $(CSS_TARGET)

$(JS_TARGET):
	@$(CAT) $(JS_SOURCE) > tmp.js
	$(JS_COMPRESSOR) -o $(JS_TARGET) tmp.js
	@$(RM) tmp.js

clean:
	$(RM) -f $(CSS_TARGET) $(JS_TARGET)
