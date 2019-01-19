#!/bin/sh

# Save DBUS_SESSION_BUS_ADDRESS to some file so cron can call notify-send.
# Make sure to lock down the file so only the owner can access it.

touch $HOME/.dbus/Xdbus
chmod 600 $HOME/.dbus/Xdbus
env | grep DBUS_SESSION_BUS_ADDRESS > $HOME/.dbus/Xdbus
echo 'export DBUS_SESSION_BUS_ADDRESS' >> $HOME/.dbus/Xdbus

exit 0
