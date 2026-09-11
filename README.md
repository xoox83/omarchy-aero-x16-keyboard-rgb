# Gigabyte Aero X16: Keyboard RGB

Omarchy bar plugin for the **one-zone RGB keyboard** on the Gigabyte AERO X16 (`USB 0414:8204`).

Set colour and brightness from the bar. It talks to the keyboard over **HID LampArray** on USB interface 4 (`hidraw`, usage page `0x59`). It does **not** unbind `usbhid`.

## Install

```bash
omarchy plugin add https://github.com/REPLACE_ME/omarchy-aero-x16-keyboard-rgb.git --enable
```

Then give your user access to the keyboard hidraw nodes (once):

```bash
sudo install -m 644 ~/.config/omarchy/plugins/staffan.aero-rgb/udev/99-aero-rgb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger -s hidraw --action=add
```

If hidraw permissions do not update, unplug nothing — just log out and in, or run:

```bash
sudo chmod 0660 /dev/hidraw*   # only needed until the next boot if the udev rule has not applied yet
```

The plugin appears on the right of the bar. Click the keyboard icon.

## Remove

```bash
omarchy plugin remove staffan.aero-rgb
sudo rm -f /etc/udev/rules.d/99-aero-rgb.rules
sudo udevadm control --reload-rules
```

## CLI

The same helper the panel uses:

```bash
~/.config/omarchy/plugins/staffan.aero-rgb/aero-rgb white
~/.config/omarchy/plugins/staffan.aero-rgb/aero-rgb '#1a6bff' 80
~/.config/omarchy/plugins/staffan.aero-rgb/aero-rgb off
```

## Requirements

- Gigabyte AERO X16 (or the same `0414:8204` keyboard)
- Omarchy with third-party shell plugins
- Python 3 (stdlib only)

## Safety

Do **not** unbind `usbhid` from this device. HID feature reports on the LampArray interface are enough. Unbinding the kernel driver has wedged the internal keyboard USB port (`error -71`) until a full power cut (including USB-C PD from a monitor).

Fn+Space is not exposed as `kbd_backlight` on Linux. Use this plugin (or the CLI) to turn the lights on.

## License

MIT
