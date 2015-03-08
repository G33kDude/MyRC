MyRC
====

An IRC client and bot framework written in [AutoHotkey](http://ahkscript.org/)
v1.1.20.00

Mentions:

* [JSON parser](github.com/cocobelgica/AutoHotkey-JSON) written by
	@cocobelgica
* [Socket library](http://www.autohotkey.com/board/topic/94376-) by Bentschi
* Documentation search function modified from TheGood's [trigram matching
	thread](http://www.autohotkey.com/board/topic/35990-)
* RichEdit class modified from just\_me's
	[Class\_RichEdit](http://ahkscript.org/boards/viewtopic.php?f=6&t=681)

-----

Don't forget to `apt-get update && apt-get upgrade`!

To install WINE (required for running MyRC on linux systems)
```
apt-get install software-properties-common
add-apt-repository ppa:ubuntu-wine/ppa
apt-get update && apt-get upgrade
apt-get install wine1.7
```

To download MyRC (It downloads to a new subdirectory called "MyRC" it creates
in the current directory)
```
apt-get install git # You can skip this line if you already have git
git clone http://github.com/G33kDude/MyRC.git
cd MyRC
wget http://ahkscript.org/download/ahk-u32.zip
unzip ahk-u32.zip
rm ahk-u32.zip
```

To install screen (required for running MyRC in the background, because I'm
too lazy to figure out the proper way to handle this. If it isn't broken,
don't fix it)
```
apt-get install screen
```

To install a virtual desktop, for if you don't have a desktop already set up
and don't want to set up a real desktop.
```
apt-get install xvfb x11vnc fluxbox
```

-----

To start the virtual desktop for the script to run on, run `start_x.sh` from
the repo, then you can connect to it through VNC to see what's going on.

To start the various MyRC bots, check out `start_bot.sh` from the repo. If
you just run it, it will automatically start all the bots.

-----

The sandbox plugin allows you to run AutoHotkey code through IRC chat commands.
There are problems (security issues) with it that have yet to be addressed, but here's
how to enable it anyway.

1. Download the sandbox dll from
	[here](http://www.golguppe.com/autohotkey/sandbox/ahksandboxansi.dll).
	(this link may change in the future)
2. Make double sure you've put the dll in a folder where it will never
	be moved. Moving it will break all sorts of things, and they aren't
	always easy to fix.
3. Run `regsvr32 ahksandboxansi.dll` as admin (or `wine regsvr32
	ahksandboxansi.dll` as normal user on linux)
4. Move the sandbox plugin from the disabled folder back into the normal
	plugin folder.

-----

Notes:

* The first time you run IRCBot, a Settings.ini will be generated. You will need to edit this file with your information.