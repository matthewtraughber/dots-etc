#!/bin/bash

###########################
# Toggle touchpad on/off
###########################
device_ID="$(xinput | grep 'SynPS/2 Synaptics TouchPad' | grep -Po 'id=\K..')"

if [[ $(xinput list-props $device_ID | grep "Device Enabled (136):") == *"0"* ]];
then
  xinput enable $device_ID;
  zenity --notification --text "Enabling touchpad"
else
  xinput disable $device_ID;
  zenity --notification --text "Disabling touchpad"
fi
