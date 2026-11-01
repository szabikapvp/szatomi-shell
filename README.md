# szatomi-shell

A Quickshell desktop shell for Hyprland, with its Hyprland config.

## Install

Works on Arch-based and Fedora-based distros. Run it as your normal user; it asks for sudo when it needs it:

```sh
curl -fsSL https://raw.githubusercontent.com/szabikapvp/szatomi-shell/main/install.sh | bash
```

The installer:

- installs Hyprland 0.56+, Quickshell and everything the shell uses (on Fedora through the `nett00n/hyprland` COPR). Tools you already use, like another network manager or PulseAudio, are left alone.
- clones the shell to `~/.config/quickshell` and links `~/.config/hypr` and `~/.config/kitty` to the configs inside it.
- moves any existing `~/.config/quickshell`, `~/.config/hypr` or `~/.config/kitty` to a `.bak-<date>` folder next to it.
- optionally builds the HyprCapture plugin (Arch only, run it from inside Hyprland for this).

Then log into Hyprland.

## Update

Run the same command again.

## Your own Hyprland settings

Don't edit `hyprland.lua`, or updates will conflict with your changes. Put your overrides in `~/.config/hypr/user.lua` instead. It loads last and updates never touch it:

```lua
hl.config({ input = { kb_layout = "us" } })
```
