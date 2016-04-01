# Otter Virtual Build Environment

The purpose of this repository is to have a consistent environment for building packages on any computer. You're going to need Vagrant, Packer, and VirtualBox. If your version of packer is older than 0.5 or so, you can change `virtualbox-iso` to `virtualbox` in the respective JSON file (such as `debian/debian-jessie64.json`) and it'll probably work.

For now the repository only contains an automated installation of Debian Jessie x64. To get started, type `make jessie64` in the root of your clone of this repository. Subsequently you can `cd debian` into the `debian` subdirectory and type `vagrant provision` to build the latest package from Git.

You can pass arguments to the virtual machine like this:

```
BUILD_DEB_ARGS='--email "Full Name <email@example.com>" --suffix "~mybuild"' vagrant provision
```
