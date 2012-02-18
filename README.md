

This repository contains the source code for two programs:

1. The `teensy` folder contains the `mouseimposter` source code.  The `mouseimposter` program runs on a [Teensy 2.0] connected by USB and describes itself as a very standard mouse.  Whenever `mouseimposter` receives a HID report on its default control pipe, it responds with a HID report indicating motion on the X axis.

2. The `mac` folder contains the `MouseLatencyApp` source code.  `MouseLatencyApp` is a Mac OS X application that uses a Teensy running `mouseimposter` to measure the latency of mouse movement events.

