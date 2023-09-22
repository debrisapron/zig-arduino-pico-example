# zig-arduino-pico-example

A simple but fully-functional [Striking Clock](https://en.wikipedia.org/wiki/Striking_clock) firmware for the [Raspberry Pi Pico W](https://www.raspberrypi.com/news/raspberry-pi-pico-w-your-6-iot-platform/), based on the [earlephilhower Arduino-Pico core](https://github.com/earlephilhower/arduino-pico), using [PlatformIO](https://platformio.org/), with the core logic written in [Zig](https://ziglang.org/).

## Hardware

If you want to actually make the thing, wire Pico GPIO 0 to one terminal of a [small speaker](https://www.adafruit.com/product/3968), and Pico ground to the other terminal*. Plug the Pico into a power source. That's it.

* I don't think it matters which way round they go but I also can't be bothered to look it up right now, so caveat emptor.

## To build & install

Please note it must be a Pico __W__, this firmware uses [NTP](https://en.wikipedia.org/wiki/Network_Time_Protocol)!

- [Install Zig](https://ziglang.org/learn/getting-started/)
- [Install PlatformIO](https://docs.platformio.org/en/latest/integration/ide/vscode.html#installation)
- Set the `SSID`, `PASSPHRASE`, and `TIMEZONE` consts in `src/core.zig`
- Plug in the Pico W
- `./build-core.sh && pio run -t upload`

## Why?

Zig is a small, highly rigorous & extremely performant language for close-to-the-metal programming, ideal for embedded systems. The earlephilhower Arduino-Pico core is a powerful omakase-style framework, exposing APIs for almost the entire Pico hardware stack. Furthermore, the Arduino ecosystem has hundreds (thousands?) of fantastically useful libraries for almost anything you might want to attach to an MCU. However Arduino-Pico and other Arduino libraries are generally written in C++ and as such cannot be used from Zig.

## How

- We have a `main.cpp` with the standard Arduino `setup` and `loop` entry points. These call into equivalent entry points in our Zig library.
- We have a HAL (Hardware Abstraction Layer) written in C and C++ containing all the API functions exposed to Zig. This is split into a standard C header file & a C++ implementation file.
- We have a Zig source file which exports its own setup & loop entry points.
- The same file also *imports* our HAL header file using Zig's C translation capability.
- We have a `build-core.sh` script which uses `zig build-lib` to compile a binary library file, making sure to point it to the location of the HAL header file.
- Going the other way, we have a `plaformio.ini` file which contains linker flags, so when we run `pio run` the linker can find the Zig-generated binaries.

Note that this design also makes it easy to test core.zig, since we can simply replace the HAL with a mock implementation.

## Areas for improvement

- It would be good to do the time and date stuff in Zig, however the docs around this are rather sparse at the moment.
- I tried to use the Zig build system to compile the object files & kick off `pio run` but I ran into terrible problems trying to get the target flags correct. I'm not sure why this is so hard, I'm probably just being dense.