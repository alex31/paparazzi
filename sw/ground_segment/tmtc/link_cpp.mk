# C++ link can also be built with: make -f link_cpp.mk PAPARAZZI_SRC=/path/to/paparazzi
# Its source lives beside the reusable library, so the same standalone CMake
# project supplies the agent, tests, installation and compiler checks.
PPRZLINK_CXX ?= g++-13
PPRZLINK_CPP_BUILD ?= $(PAPARAZZI_SRC)/var/build/pprzlink-cpp
PPRZLINK_CMAKE_OPTIONS ?=
CPP_LINK_OUTPUT ?= link++
PPRZLINK_BUILD_JOBS ?= 4

.PHONY: link++
link++:
	cmake -S "$(PAPARAZZI_SRC)/sw/ext/pprzlink/lib/v2.0/C++" -B "$(PPRZLINK_CPP_BUILD)" \
	  -DCMAKE_CXX_COMPILER="$(PPRZLINK_CXX)" -DCMAKE_BUILD_TYPE=Release \
	  -DPPRZLINK_BUILD_LINK=ON -DPPRZLINK_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF $(PPRZLINK_CMAKE_OPTIONS)
	cmake --build "$(PPRZLINK_CPP_BUILD)" --target link++ --parallel "$(PPRZLINK_BUILD_JOBS)"
	cp "$(PPRZLINK_CPP_BUILD)/apps/link/link++" "$(CPP_LINK_OUTPUT)"
