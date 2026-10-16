# Try the C++23 pprzlink branch

This branch publishes the C++ library work in
[alex31/pprzlink, FEATURE/ivycpp_native](https://github.com/alex31/pprzlink/tree/FEATURE/ivycpp_native).
Paparazzi pins its exact commit as the sw/ext/pprzlink submodule and uses the
fork's HTTPS URL, so collaborators can fetch it without write access.

The library uses Ivy's native C++23 wrapper, typed field storage and concepts,
complete serial writes, and exclusive ownership of transport devices.
It also provides an XBee 802.15.4 AP=1 transport with checked AT initialization,
automatic baud discovery (target 57600 by default), verified baud persistence,
and optional validation before sending a binary frame.

The serial_messages executable is a diagnostic example. The new link++
ground agent implements the OCaml link's CLI, routing and supervision. Its
source and differential tests live in the pprzlink submodule.
See [the implementation and comparison report](../sw/ext/pprzlink/lib/v2.0/C++/LINK_CPP_VALIDATION.md)
for build-time selection with LINK_IMPL=cpp and the documented differences.
The [public API examples](../sw/ext/pprzlink/lib/v2.0/C++/API_USAGE.md) cover scoped Ivy subscriptions, checked numeric conversions and serial/UDP clients.
The core and I/O components can be used without Ivy.

## Get the source

For this C++ library, initialize pprzlink and its pinned LLNL/units dependency recursively:

```sh
git clone --branch FEATURE/ivycpp_native \
  --recurse-submodules=sw/ext/pprzlink \
  https://github.com/alex31/paparazzi.git
cd paparazzi
```

In an existing checkout, after fetching and checking out the branch:

```sh
git submodule sync --recursive -- sw/ext/pprzlink
git submodule update --init --recursive sw/ext/pprzlink
```

To work on the rest of Paparazzi, initialize its other submodules with
`git submodule update --init --recursive` and follow the normal Paparazzi
installation instructions. The submodule is normally checked out at a detached
commit: do not update it to its default master branch to build this feature.

LLNL/units is built automatically from `sw/ext/pprzlink/third_party/llnl_units`
and installed with the C++ SDK. Paparazzi's normal `make` already runs the
recursive pprzlink submodule update; no separate LLNL installation is needed.

## Install Ivy and the C++ build dependencies

Ubuntu 24.04 / GCC 13 is the validated minimum: GCC 13.3 builds the library
and agent and passes the tests, including comparison with the real OCaml link.
Earlier validation was performed on Ubuntu 26.04.1 with GCC 15 and Clang 22.
Ubuntu 22.04 is not supported by this branch.

Use Ivy **3.18.3**, including its C++23 wrapper. The exact tested source is
[alex31/libivy-c at b0bf831702c5bfd1313e83ded62eb14d17198534](https://github.com/alex31/libivy-c/commit/b0bf831702c5bfd1313e83ded62eb14d17198534),
on branch FEATURE/cpp_wrapper. Ivy is installed separately, not vendored into
Paparazzi or pprzlink. The old pprzlink ivy-c++ directory has been removed.

Install the library/test dependencies and the Ivy package build dependencies:

```sh
sudo apt-get install build-essential cmake pkg-config python3 \
  libboost-dev libtinyxml2-dev debhelper libxt-dev libx11-dev tcl-dev \
  libglib2.0-dev libpcre2-dev libreadline-dev doxygen graphviz \
  texlive-latex-base texlive-latex-recommended texlive-latex-extra \
  texlive-plain-generic texlive-fonts-recommended poppler-utils
```

Build the Ivy packages on the target machine. This also builds their PDF
reference. In a separate directory from the Paparazzi checkout:

```sh
git clone --branch FEATURE/cpp_wrapper https://github.com/alex31/libivy-c.git
cd libivy-c
git checkout b0bf831702c5bfd1313e83ded62eb14d17198534
IVY_DEB_OUTPUT_DIR="$PWD/build/debian/3.18.3" sh debian/build.sh -j4
python3 debian/check-packages.py build/debian/3.18.3
sudo apt-get --no-remove install \
  "$PWD/build/debian/3.18.3/ivy-c_3.18.3_$(dpkg --print-architecture).deb" \
  "$PWD/build/debian/3.18.3/ivy-c-dev_3.18.3_$(dpkg --print-architecture).deb"
pkg-config --modversion ivy-c ivy-cpp
```

Both pkg-config queries should report 3.18.3. If using a private Ivy prefix,
set PKG_CONFIG_PATH and LD_LIBRARY_PATH as documented in the pprzlink README.
Do not mix headers and runtime libraries from different Ivy installations.
Prebuilt Ubuntu 26 packages are not a substitute for a target-platform build.

## Build both ground link agents

After installing the Paparazzi and C++ dependencies, run `make` from the
Paparazzi root. It builds both `sw/ground_segment/tmtc/link` (OCaml by default)
and `sw/ground_segment/tmtc/link++` (C++), using the installed Ivy libraries.
The C++ build uses GCC 13 by default; `PPRZLINK_CXX` selects another compiler.

`make LINK_IMPL=cpp` also builds `link++` and copies it to `link` for use with
existing launch commands. Run `make LINK_IMPL=ocaml` to restore the OCaml
executable at `link`.

For a direct launch outside Paparazzi Center, set the environment from the
Paparazzi root before running either agent:

```sh
export PAPARAZZI_HOME="$PWD"
export PAPARAZZI_SRC="$PWD"
./sw/ground_segment/tmtc/link --help
./sw/ground_segment/tmtc/link++ --help
```

Both agents read `$PAPARAZZI_HOME/var/messages.xml`, generated by `make`.
`PPRZLINK_DIR` overrides the directory containing `messages.xml`. Without
either variable, they use `/usr/share/pprzlink/messages.xml`.

For XBee, enable RTS/CTS with `-hfc` when the RTS/CTS lines are connected:

```sh
./sw/ground_segment/tmtc/link++ \
  -transport xbee -d /dev/ttyUSB0 -s 57600 -hfc
```

The option configures and verifies both the host serial port and the modem's
`D6`/`D7` functions. Without `-hfc`, both sides have flow control disabled.
The selected baudrate stays fixed and is not saved to flash. The same `-hfc`
argument can be added to the link++ launch command in Paparazzi Center.

Each message can declare `radio_retry="true"` or `radio_retry="false"` on its
`<message>` element in the loaded XML. The agent uses
`RadioRetries::FromDefinition`: a missing attribute preserves the existing
retry behavior. A false value disables radio ACK/retries and host resends
after a radio failure. A true or missing value allows host resends up to
`-xbee_retries` (default 10 total attempts, including the first transmission).
Transmit status tracking remains enabled in either case; a missing status
does not trigger a blind resend. Restart the agent after changing the XML,
and check `$PAPARAZZI_HOME/var/messages.xml` when using a generated catalogue.
See [the pprzlink guide](../sw/ext/pprzlink/lib/v2.0/C++/guide_d_utilisation.md#utiliser-link-avec-une-radio-xbee)
for the complete policy and standalone build instructions.

For a virtual serial connection on Linux, let `link++` manage socat:

```sh
./sw/ground_segment/tmtc/link++ -socat start
./sw/ground_segment/tmtc/link++ -d /dev/pts/N -transport pprz -s 57600
./sw/ground_segment/tmtc/link++ -socat stop
```

Use either **Port A** or **Port B** printed by `start` in place of `/dev/pts/N`;
the other program opens the remaining port. Both ends are interchangeable and
carry data in both directions. `socat` must be on PATH. The
management commands return immediately and do not require the Paparazzi
environment. Repeating `start` reuses the same pair; `stop` terminates only the
managed socat process and removes the virtual ports.

## Build and test pprzlink

From the Paparazzi root:

```sh
cmake -S sw/ext/pprzlink/lib/v2.0/C++ -B build/pprzlink-cpp \
  -DCMAKE_BUILD_TYPE=Debug
cmake --build build/pprzlink-cpp -j4
ctest --test-dir build/pprzlink-cpp --output-on-failure
./build/pprzlink-cpp/serial_messages --help
```

The default build now runs 19 tests without a physical radio. They include Ivy loopback communication
and serial/XBee emulation through pseudo-terminals. The runtime must permit
loopback UDP/TCP sockets and pseudo-terminal creation.

For a compatible 802.15.4 modem on /dev/ttyUSB0:

```sh
./build/pprzlink-cpp/serial_messages \
  -messages sw/ext/pprzlink/message_definitions/v1.0/messages.xml \
  -d /dev/ttyUSB0 -transport xbee -xbeesan
```

Autobaud is enabled automatically and targets 57600 baud; -s selects another
supported target. A changed rate is checked before ATWR saves it. ATWR also saves
the modem's other existing parameters, before this initializer changes MY/CH/AP.
Initialization errors block binary sends and are printed on stderr.
Physical XBee behavior, including persistence after a power cycle, still needs
hardware validation. Only legacy 802.15.4 AP=1 framing is supported.

## Review and integration

See the [C++ README](https://github.com/alex31/pprzlink/blob/756d00d1a88f8b7ad0a2c2a8ac6e98bf6fca34e6/lib/v2.0/C%2B%2B/README.md) for the library API,
migration instructions, transport formats and examples, and
[the validation report](https://github.com/alex31/pprzlink/blob/756d00d1a88f8b7ad0a2c2a8ac6e98bf6fca34e6/lib/v2.0/C%2B%2B/pprzlink/VALIDATION_CLANG22.md)
for test coverage and limitations. Downstream C++ applications must be adapted
to the changed APIs and rebuilt.

The Paparazzi commit updates the submodule URL, pinned commit and this guide.
The full Paparazzi application and aircraft firmware have not been validated by
the C++ library test suite.
