#!/usr/bin/env python3
import ctypes
import ctypes.util
import subprocess
import sys

def main():
    try:
        x11 = ctypes.cdll.LoadLibrary(ctypes.util.find_library('X11'))
    except Exception as e:
        subprocess.run(['notify-send', '-a', 'i3', 'Keyboard Layout Error', f'Failed to load libX11: {e}'])
        sys.exit(1)

    display = x11.XOpenDisplay(None)
    if not display:
        subprocess.run(['notify-send', '-a', 'i3', 'Keyboard Layout Error', 'Could not open X Display'])
        sys.exit(1)

    class XkbStateRec(ctypes.Structure):
        _fields_ = [
            ('group', ctypes.c_ubyte),
            ('locked_group', ctypes.c_ubyte),
            ('base_group', ctypes.c_short),
            ('latched_group', ctypes.c_short),
            ('mods', ctypes.c_ubyte),
            ('base_mods', ctypes.c_ubyte),
            ('latched_mods', ctypes.c_ubyte),
            ('locked_mods', ctypes.c_ubyte),
            ('compat_state', ctypes.c_ubyte),
            ('grab_mods', ctypes.c_ubyte),
            ('compat_grab_mods', ctypes.c_ubyte),
            ('lookup_mods', ctypes.c_ubyte),
            ('compat_lookup_mods', ctypes.c_ubyte),
            ('ptr_buttons', ctypes.c_ushort)
        ]

    state = XkbStateRec()
    # 0x0100 is XkbUseCoreKbd
    x11.XkbGetState(display, 0x0100, ctypes.byref(state))

    # Toggle between Group 0 (French AZERTY) and Group 1 (Arabic AZERTY)
    next_group = 1 if state.group == 0 else 0
    x11.XkbLockGroup(display, 0x0100, next_group)
    x11.XFlush(display)
    x11.XCloseDisplay(display)

    if next_group == 1:
        layout_name = "Arabic (AZERTY)"
        info = "العربية - AZERTY"
    else:
        layout_name = "French (AZERTY)"
        info = "Français - AZERTY"

    subprocess.run([
        'notify-send',
        '-a', 'i3',
        '-t', '1500',
        '-h', 'string:x-canonical-private-synchronous:keyboard-layout',
        '  Keyboard Layout',
        f'Switched to: {layout_name}\n{info}'
    ])

if __name__ == '__main__':
    main()
