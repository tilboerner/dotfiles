# Prevents the displays from being turned off when GNOME blanks the screen.
# Window placement gets messed up when returning from lockscreen.
# Since GNOME offers no setting to not blank the screen on the lock screen,
# hard-disable dpms (power management) signals.
#
# https://bugzilla.gnome.org/show_bug.cgi?id=710904#c87
xset -dpms
