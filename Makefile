.DEFAULT_GOAL = help

CHAPTERS = \
	Chapters/Mocketry/Mocketry \
	Chapters/BabyMock/BabyMock \
	Chapters/StateSpecs/StateSpecs \

# Redirect to bootstrap makefile if pillar is not found
PILLAR ?= $(wildcard pillar)
ifeq (,$(PILLAR))
	include support/makefiles/bootstrap.mk
else
	include support/makefiles/main.mk
endif
