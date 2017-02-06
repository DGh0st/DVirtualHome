include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DVirtualHome
DVirtualHome_FILES = DVHRootListController.m
DVirtualHome_INSTALL_PATH = /Library/PreferenceBundles
DVirtualHome_FRAMEWORKS = UIKit MessageUI
DVirtualHome_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/DVirtualHome.plist$(ECHO_END)
