# Gigabyte Aero X16: Keyboard RGB

Omarchy bar plugin for the **one-zone RGB keyboard** on the Gigabyte AERO X16 (`USB 0414:8204`).

Set colour and brightness from the bar. It talks to the keyboard over **HID LampArray** on USB interface 4 (`hidraw`, usage page `0x59`). It does **not** unbind `usbhid`.

## Install

```bash
omarchy plugin add https://github.com/xoox83/omarchy-aero-x16-keyboard-rgb.git --enable
```

Then give your user access to the keyboard hidraw nodes (once). This writes a
**built-in allowlisted** udev rule as root — it does not copy files from the
plugin directory:

```bash
sudo /usr/bin/python3 -I ~/.config/omarchy/plugins/xoox.aero-x16-rgb/aero-rgb --install-udev
```

If hidraw permissions do not update, log out and in. Do not chmod `/dev/hidraw*`.

The plugin appears on the right of the bar. Click the keyboard icon.

## Remove

```bash
omarchy plugin remove xoox.aero-x16-rgb
sudo /usr/bin/python3 -I ~/.config/omarchy/plugins/xoox.aero-x16-rgb/aero-rgb --remove-udev
```

`--remove-udev` only deletes the rule if it still matches the allowlisted bytes.

## CLI

The same helper the panel uses:

```bash
~/.config/omarchy/plugins/xoox.aero-x16-rgb/aero-rgb white
~/.config/omarchy/plugins/xoox.aero-x16-rgb/aero-rgb '#1a6bff' 80
~/.config/omarchy/plugins/xoox.aero-x16-rgb/aero-rgb off
~/.config/omarchy/plugins/xoox.aero-x16-rgb/aero-rgb cycle
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
