## iCEBreaker FPGA Workshop

Welcome to the iCEBreaker FPGA workshop repository.

This workshop is self directed and can be done on your own time.


## iCEBreaker workshop sessions

* [Crowd Supply Teardown conference](https://www.crowdsupply.com/teardown/portland-2019) in Portland Oregon 21st-23rd June 2019. 
* [Chaos Communication Congress 36C3](https://events.ccc.de/congress/2019/wiki/index.php/Session:ICEBreaker_FPGA_Workshop)
in Leipzig Germany 27th-30th December 2019.

## Supplies needed

* Computer
* Micro USB cable (make sure it is a data cable not just a charge cable)
* [iCEBreaker](https://1bitsquared.com/products/icebreaker)
* [iCEBreaker 7Segment display](https://1bitsquared.com/products/pmod-7-segment-display)
  * You might need one or two displays depending on the workshop you choose.

**Note:** In most cases we provide the iCEBreaker hardware for the duration of the
workshop. You will have to return it after the workshop is over. Make sure to
read the specific workshop instructions. We usually also have extra hardware
you can purchase so you can keep hacking on it and take home. Also refer to the
workshop instructions of how to get the hardware or ping [@esden on
twitter](https://twitter.com/esden).

## Toolchain installation

Follow the instructions on the [fomu-toolchain
README](https://github.com/im-tomu/fomu-toolchain) to install the FPGA
toolchain on your computer.

## I am ready let's GO!

Now that you have all the supplies and the toolchain installed go ahead and
clone this repository:

```
git clone https://github.com/icebreaker-fpga/icebreaker-workshop.git
cd icebreaker-workshop/stopwatch
```

In the stopwatch directory you will find the workshop guide PDF. Follow the
instructions inside the PDF. If you happen to do the workshop as part of an
organized class the helpers are here to help you out when you have questions or
you get stuck somewhere. Do not hesitate to ask for help, this is why we are
here.

If you are doing the workshop on your own time and you want to share your
experiances or want to ask a question, [join our Discord
server](https://1bitsquared.com/pages/chat)!

## Troubleshooting

**I am running iceprog and the programmer is not being detected**

**Linux**

* Check if the device is being detected by the kernel with 'lsusb' it will
  either show up as a Future Electronics device or the name of the programmer
  vendor.
* If the device is being detected by the kernel you might not have permissions
  to access the device. If you run `sudo iceprog ...` and the device is
  decected you can give yourself permissions by creating a udev file at:
  `/etc/udev/rules.d/53-icebreaker-ftdi.rules` and adding the following line in
  that file:
```
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"
```
After adding that file you need to at least replug the programmer or even
reload the udev rules.

**Windows**

You will need the [zadig drivers](https://zadig.akeo.ie/) and libusb1.
