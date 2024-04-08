# Description
Correctly configures LXC so that it works properly in Termux.
<br>

#### What's LXC?
https://www.reddit.com/r/termux/comments/185qynj/where_you_run_desktop_environtment/kb8kad5
>Termux provides the `lxc` package for those with root/custom-kernels, which by far provides the most complete desktop experience possible.
>
>It runs distros at native speeds and supports systemd, snapd, flatpaks and snap packages. Absolutely my goto for running Ubuntu in Termux.
>
>You can toggle services normally (unlike chroot/proot where it's broken), you can install snaps like chromium, firefox, etc., (again, unlike chroot/proot where snaps don't work) and have a full-blown desktop experience.
>
>In fact, the experience gets soo real that you can even **run Android emulators** in it -
>
>**[Termux in Waydroid, inside Ubuntu, inside Termux, running in Android](https://ibb.co/X8H0mdQ)**
>
>(Here I'm running Ubuntu inside Termux(LXC), and inside that Ubuntu I can even run the Waydroid Android emulator and inside Waydroid I'm running Termux as demo)
>
>(Waydroid also runs native, that means no qemu to slow it down)
>

https://f-droid.org/en/packages/com.termux/

https://github.com/lxc/lxc

<br>

# Instructions
In Termux -

```
git clone --depth 1 https://github.com/George-Seven/Termux-LXC-Guide ~/Termux-LXC-Guide
```
```
bash ~/Termux-LXC-Guide/setup-termux-lxc.sh
```
And done.

```
 Termux LXC configurations completed.

 If you haven't created a container yet, you can
 create a new Ubuntu container using this command -

  sudo lxc-create -t download -n ubuntu -- --no-validate -d ubuntu -r jammy -a arm64


 You can login to the container using -

  sudo lxc-start -F -n ubuntu

 Eg:- username is 'ubuntu' and password is 'password'
      without quotes.
```
<br>

### Useful tips
#### Create a container -
```
sudo lxc-create -t download -n ubuntu -- --no-validate -d ubuntu -r jammy -a arm64
```
<br>

#### Start a container -
```
sudo lxc-start -F -n ubuntu
```
<br>

#### Start a container as detached -
```
sudo lxc-start -d -n ubuntu
```
<br>

#### Login to a detached container -
```
sudo lxc-console -n ubuntu
```
<br>

#### Stop a container -
```
sudo lxc-stop -k -n ubuntu
```
<br>

#### Stop a container from inside the container -
```
sudo shutdown now
```
<br>

#### Get information of the container -
```
sudo lxc-info -n ubuntu
```
<br>

#### Run commands in a running container -
```
sudo lxc-attach -n ubuntu --clear-env -q -- usr/bin/bash -c "echo Hello World"
```
<br>

#### Delete a container -
```
sudo lxc-destroy -n ubuntu
```
<br>

#### List all commands -
```
dpkg -L lxc | grep $PREFIX/bin
```
<br>

Check out the configuration comments [here](https://github.com/George-Seven/Termux-LXC-Guide/blob/main/src/required-lxc-configuration/scripts/utils/utils.pre-start.sh).

<br>

## Sound?
Works out of the box.

<br>

## Networking?
Wi-Fi and mobile data works out of the box.

>**Note:-** VPN of the phone doesn't work inside the container.

<br>

## Display?
Many options, I recommend VNC or Termux:X11.

### Using VNC
Login to the container.

Install some desktop like XFCE or GNOME.

Eg. -
```
sudo apt update
```
```
sudo apt install -y xfce4 xfce4-session xfce4-terminal tigervnc-standalone-server tigervnc-tools dbus-x11
```
After that -
```
export DISPLAY=:1
```
```
vncserver -localhost no :1
```

<br>

Use a VNC viewer app like RVNC to view the GUI.

>**Hint:-** Each container has it's own local IP address, ie:- 10.0.4.X
>
> You can check the IP address of the container by -
>```
>sudo lxc-info -n ubuntu
>```
>
> And use this IP address in the RVNC viewer app to view it.
>
>ie:- `10.0.4.100:1`

<br>

### Using Termux:11
Same steps, install some desktop like XFCE.

Download [Termux:X11](https://github.com/termux/termux-x11/releases).

In Termux -

```
pkg install -y termux-x11-nightly
```
```
termux-x11 :1
```

Login to the container.

>**Hint:-** To open a new Termux terminal pane, slide slowly from the middle left-most to the right and select new session.

In a new terminal pane run -
```
CONTAINER="ubuntu"; sudo bash -c "mkdir '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.X11-unix 2>/dev/null'; mount --bind '${PREFIX}/tmp/.X11-unix' '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.X11-unix'"
```
Where `ubuntu` is the container.

Go back to the container terminal and run -
```
export DISPLAY=:1
```
```
dbus-launch --exit-with-session xfce4-session 2>/dev/null >/dev/null &
```

The GUI will be running in the Termux:X11 app.

<br>

### Hardware acceleration
Like how the guide for [hardware acceleration in chroot/proot](https://github.com/LinuxDroidMaster/Termux-Desktops/blob/main/Documentation/HardwareAcceleration.md#2-initialize-graphical-server-in-termux) uses `virgl` server and socket, you can also pass the socket to the container for hardware acceleration.

Follow the steps in that section and in a terminal pane run the command -
```
CONTAINER="ubuntu"; sudo bash -c "touch '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.virgl_test'; mount --bind '${PREFIX}/tmp/.virgl_test' '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.virgl_test'; chmod 777 '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.virgl_test'"
```

And then run programs with hardware acceleration enabled as mentioned [here](https://github.com/LinuxDroidMaster/Termux-Desktops/blob/main/Documentation/HardwareAcceleration.md#3-in-proot-distro).

