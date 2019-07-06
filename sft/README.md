# Summon-FPGA-Tools

This is a copy of the SFT project that you can find at:
https://github.com/esden/summon-arm-toolchain

This copy of the script has only the tools enabled that we will need for this
workshop.

SFT is a small and flexible script that builds a open-source
FPGA tools. These tools consist from:

* Yosys
* prjtrellis (ecp5 database) (disabled)
* nextpnr-ice40
* nextpnr-ecp5 (disabled)
* arachne-pnr (disabled)
* icestorm
* icarus-verilog (disabled)

More tools will be added over time. The current candidates are:

* verilator
* gtkwave

This script is intended to not require super user privileges and installs all
the tools into `${HOME}/sft` directory. Obviously you will need some rights to
install the dependencies provided by your operating system.

As many of the tools don't have official release tarballs, and the tools are
still in very rapid development we are currently building the newest `master`
releases of all the tools.

## Dependencies

You will need to install the following dependencies to be able to run this
script.

### Debian/Ubuntu/Mint/Raspbian

```
sudo apt-get install git mercurial build-essential bison clang cmake \
                     flex gawk graphviz xdot libboost-all-dev \
                     libeigen3-dev libffi-dev libftdi-dev libgmp3-dev \
                     libmpfr-dev libncurses5-dev libmpc-dev \
                     libreadline-dev zlib1g-dev pkg-config python \
                     python3 python3-dev tcl-dev autoconf gperf \
                     qtbase5-dev libqt5opengl5-dev
```

### openSUSE

```
zypper in  patterns-devel-python-devel_python3 patterns-devel-base-devel_basis \
           mercurial bison clang cmake flex gawk graphviz xdotool eigen3-devel \
           libffi-devel libftdi0-devel libgmp10 libmpfr6 libncurses5 \
           ncurses5-devel libmpc3 libreadline6 zlib-devel pkg-config python \
           python3 python3-devel tcl-devel autoconf gperf \
           libboost_headers1_66_0-devel libboost_system1_66_0-devel \
           libboost_serialization1_66_0-devel libboost_regex1_66_0-devel \
           libboost_program_options1_66_0-devel libboost_iostreams1_66_0-devel \
           libboost_chrono1_66_0-devel libboost_atomic1_66_0-devel \
           libboost_filesystem1_66_0-devel libboost_date_time1_66_0-devel \
           libboost_thread1_66_0-devel libboost_python-py3-1_66_0-devel
```

### Mac OS

XCode with command line tools.

```
brew install cmake python boost boost-python3 qt5 git libftdi0 bison gperf \
	     eigen pkg-config libffi autoconf
```

For additional information regarding Mac OS, refer to the [project IceStorm
documentation](http://www.clifford.at/icestorm/notes_osx.html).

## To compile the open source FPGA tools:

* `git clone https://github.com/esden/summon-fpga-tools.git`
 or
* `wget https://github.com/esden/summon-fpga-tools/zipball/master; unzip master`
* `cd summon-fpga-tools`
* `./summon-fpga-tools.sh`
* `export PATH=~/sft/bin:$PATH`
* Profit

## Command line options

You can suffix the script call with the following variable parameters:

### `PREFIX=`

By default the installation prefix is `${HOME}/sft` you can change it to `/usr`
or `/usr/local` then the binaries will be installed into `${HOME}/sft/bin`,
`/usr/bin` or `/usr/local/bin` respectively.

### `SUDO=`

By default this variable is empty. If you need root rights for the install
step you may set this variable to `sudo`.

```
$ ./summon-fpga-tools.sh SUDO=sudo
```

This will prefix all make install steps with the sudo command asking for
your root password.

### `QUIET=`

By default set to 0. To decrease console output (may increase compile speed
in some cases) you can set this variable to 1.

### `CPUS=`

Overrides the autodetection of CPU cores on the host machine. This option
is translated into the `-j$CPUS+1` option to the make command when running
the script.

### `NEXTPNR_BUILD_GUI=`

If building for a headless machine, set to `off` and skip the QT dependencies
above.

## Example:

```
$ ./summon-fpga-tools.sh CPUS=5
```

This will run the script with 5 CPUs on your host machine resulting in calling
all make commands with `-j6`.

## Troubleshooting

**I am running iceprog and the programmer is not being detected**

* Check if the device is being detected by the kernel with 'lsusb' it will
  either show up as a Future Electronics device or the name of the programmer
  vendor.
* If the device is being detected by the kernel you might not have permissions
  to access the device. If you run `sudo iceprog ...` and the device is
  decected you can give yourself permissions by creating a udev file at:
  `/etc/udev/rules.d/53-lattice-ftdi.rules` and adding the following line in
  that file:
```
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"
```
After adding that file you need to at least replug the programmer or even
reload the udev rules.

**I am getting an error during iverilog installation**

IcarusVerilog build system is little bit broken when running on multiple
processes as it's dependencies are not set up correctly. You might need to run
the summon-fpga-tools script twice so that the installation succeeds. If the
issue persists after the second try, consider opening an issue either for
iverilog or SFT, and we will try to get it sorted out. :)

## Questions:

If you have any questions please contact us on gitter. Please contribute
suggestions in for of issues and pull requests! :D
