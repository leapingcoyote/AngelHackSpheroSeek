# Bluetooth LE, Core Bluetooth, and a Glimpse Into Your Near Future

Bluetooth LE is Bluetooth's low power, low latency companion with tons of potential, and it's built into your phone and laptop. Bluetooth LE is cheap, accessible, hackable, and powerful. I'll discuss the current state of Bluetooth LE, why it's awesome, and introduce Core Bluetooth on iOS. Learn how to use it to connect to Bluetooth LE accessories and iOS devices. We'll experiment with dev kits and code and discuss gotchas/limitations of the framework.

This repository contains slides and code samples to accompany my talk.

## Slides

[BLERules.pdf](https://github.com/livefront/blerules/Slides/BLERules.pdf)

## Demo App

[Source Code](https://github.com/livefront/blerules/Source/iPhone/)

The demo app is configured to connect to, read from, and write to an [Arduino](http://www.arduino.cc/) with a [BLE-Shield](http://www.mkroll.mobi/?page_id=681) attachment. It'll work with other peripherals, but it will only display RSSI values.

## Bluetooth Low Energy Devices

Here's a list of Bluetooth Low Energy devices that were referenced in the talk. (I don't have any affiliation with these companies other than that I think they're awesome.)

* [Bluetooth Smart Devices from the Bluetooth SIG](http://www.bluetooth.com/Pages/Bluetooth-Smart-Devices-List.aspx)
* [FitBit One](http://www.fitbit.com/one)
* [Myo](https://getmyo.com/faq)
* [hipKey](http://www.hippih.com/)
* [COOKOO](http://www.cookoowatch.com/)
* [Automatic](http://www.automatic.com/)
* [Stick-N-Find](http://www.sticknfind.com/)

## References for Factoids

* Slide 7: [Jonathan Cassell, IMS Research](http://www.imsresearch.com/press-release/Is_the_Google_Platform_Delaying_the_Bluetooth_Smart_Train&cat_id=188&from=)
* Slide 7: [Alex West, IMS Research](http://www.imsresearch.com/press-release/The_Slow_Road_from_Classic_Bluetooth_to_Bluetooth_Smart_in_Consumer_Medical_Devices&cat_id=165&from=)
* Slide 27: [Joakim Linde, Apple](https://developer.apple.com/videos/wwdc/2012/)
* Slide 28: [Various, Wikipedia](http://en.wikipedia.org/wiki/Bluetooth_low_energy)

## Third-Party Attribution

[Source Sans Pro by Paul D. Hunt](http://www.google.com/webfonts/specimen/Source+Sans+Pro)

## License

Copyright (c) 2013 Sam Kirchmeier
Livefront
http://livefront.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

