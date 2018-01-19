export ARCHS = armv7 arm64
export TARGET = iphone:clang:8.1:latest

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DVirtualHome
DVirtualHome_FILES = Tweak.xm
DVirtualHome_FRAMEWORKS = UIKit AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += dvirtualhome
include $(THEOS_MAKE_PATH)/aggregate.mk
