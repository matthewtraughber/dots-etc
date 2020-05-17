
### nvidia on Fedora
`sudo dnf install akmod-nvidia`
> *https://rpmfusion.org/Howto/NVIDIA*
---
### fixing grub resolution
`sudo vim /etc/default/grub`

```
GRUB_GFXMODE=3440x1440x32
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_TERMINAL_OUTPUT="gfxterm"
GRUB_CMDLINE_LINUX="... quiet splash"
```
> *https://wiki.archlinux.org/index.php/GRUB/Tips_and_tricks*
---
### updating grub
```
# ubuntu
sudo update-grub

# fedora
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
sudo dracut --force
```
> *https://www.reddit.com/r/Fedora/comments/edq8xu/how_to_change_grub_resolution_f31/*
---
### bluetooth issues
Specifically **BCM20702A1-0b05-17cf.hcd**
> - *https://askubuntu.com/questions/632336/bluetooth-broadcom-43142-isnt-working/985016#985016*
> - *https://github.com/winterheart/broadcom-bt-firmware/tree/master/brcm*
---
