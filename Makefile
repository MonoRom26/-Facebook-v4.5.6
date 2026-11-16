TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FacebookLegacyFix

FacebookLegacyFix_FILES = Tweak.x
FacebookLegacyFix_CFLAGS = -fobjc-arc
FacebookLegacyFix_FRAMEWORKS = UIKit Foundation AVFoundation Security

include $(THEOS)/makefiles/tweak.mk

