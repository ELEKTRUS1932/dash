# OpenDash
This is a fork to create a full automated installation for a Trabant Android Auto image.
Just create a normal raspberry pi image and boot it. (See Installscript.)
Currently there is no such thing for really reset to factory settings.
You just have the default option from openDsh to uninstall it.

Please do not use the other scripts than autoinstall.
You can modify and use it on your own risk.
This autoinstall is tested on an Raspberry Pi 5 with 8GB ram.
4GB should also work with no problem.
2GB might work but could get problems while building and installing all the stuff.
But i don't know exactly
After that 2GB is absolutly enough. 

Its fully customized for the Waveshare 5.5inch 2K Display: https://www.waveshare.com/wiki/5.5inch_1440x2560_LCD
More or less just plug and play.
Its based on the opendash repository from Cole Brinsfield (icecube45)
The openDsh is currently not customized. But it may be on a future release.

OpenDash is a Qt-based infotainment center for your Linux OpenAuto installation!
The OpenDash project includes OpenAuto, AASDK, and Dash.

Main features of Dash include:

*	Embedded OpenAuto `Windowed/Fullscreen`
*	Wireless OpenAuto Capability
*	On-screen Volume, Brightness, & Theme Control
*	Responsive Scalable UI `Adjustable for screen size`
*	Bluetooth Media Control
*	Real-Time Vehicle OBD-II Data & SocketCAN Capabilities
*	Theming `Dark/Light mode` `Customizable RGB Accent Color`
*	True Raspberry Pi 7” Official Touchscreen Brightness Control
*	App-Launcher built in
*	Camera Access `Streaming/Local` `Backup` `Dash`
*	Keyboard Shortcuts `GPIO Triggerable`

![](docs/imgs/opendash-ui.gif)

# Getting Started

## Video walk through
_steps may be slightly different such as ia (intelligent-auto) has been renamed to dash, the UI has changed, etc..._

https://youtu.be/CIdEN2JNAzw


## Install Script (For openDash / Full setup of raspberry pi 5)
cd /home/pi
wget https://raw.githubusercontent.com/ELEKTRUS1932/dash/develop/autostart.sh
sudo chmod +x autostart.sh
sudo ./autostart.sh

## Install Script (OLD)

Dash can be built automatically utilizing an included script.

The install script included in the dash repo will install all the required packages and compile all portions of the OpenDash project.

### 1. Clone the repo, Run the install script
```
git clone https://github.com/openDsh/dash

cd dash

./install.sh
```
