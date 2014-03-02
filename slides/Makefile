WINTERSMITH = wintersmith
RSYNC = rsync
CONTENT_PATH = contents
BUILD_PATH = build
SRC_YML = $(shell find $(CONTENT_PATH) -type f -name '*.yml')
SRC_MD = $(shell find $(CONTENT_PATH) -type f -name '*.markdown')
SRC_JADE = $(shell find $(CONTENT_PATH) -type f -name '*.jade')
SRC = $(join $(SRC_YML), $(SRC_MD)) $(SRC_JADE)
TARGET = $(patsubst $(CONTENT_PATH)/%.yml,$(BUILD_PATH)/%.html,$(SRC_YML)) $(patsubst $(CONTENT_PATH)/%.markdown,$(BUILD_PATH)/%.html,$(SRC_MD)) $(patsubst $(CONTENT_PATH)/%.jade,$(BUILD_PATH)/%.html,$(SRC_JADE))

.PHONY: build

build: $(TARGET)
	rsync -au $(BUILD_PATH)/* ../out/slides

$(TARGET): $(SRC_YML) $(SRC_MD) $(SRC_JADE)
	$(WINTERSMITH) build
	
