MyRC
====

An IRC client and bot framework written in <a href="http://ahkscript.org/">AutoHotkey</a>

<ol>
    <li><a href="https://github.com/Jim-VxE/AHK-Lib-JSON_ToObj/">JSON parser</a> written by VxE. Copyright info in Json.ahk</li>
    <li><a href="http://www.autohotkey.com/board/topic/94376-socket-class-%C3%BCberarbeitet/">Socket library</a> by Bentschi</li>
    <li>Documentation search function modified from TheGood's <a href="http://www.autohotkey.com/board/topic/35990-string-matching-using-trigrams/">trigram matching thread</a></li>
    <li>RichEdit class modified from just_me's <a href="http://ahkscript.org/boards/viewtopic.php?f=6&t=681">Class_RichEdit</a></li>
</ol>

-----

apt-get udpate && apt-get upgrade

To install WINE
```
apt-get install software-properties-common
add-apt-repository ppa:ubuntu-wine/ppa
apt-get update && apt-get upgrade
apt-get install wine1.7
```

To download MyRC (requires git)
```
git clone http://github.com/G33kDude/MyRC.git
cd MyRC
wget http://ahkscript.org/download/ahk-u32.zip
unzip ahk-u32.zip
```

To install screen
```
apt-get install screen
```

-----

If you don't have a monitor or X display set up (running headless)
```
apt-get install xvfb x11vnc fluxbox
```

To set up virtual display for the script to run on (requires screen)
```
export DISPLAY=:0
screen -S xvfb -d -m Xvfb -screen 0 800x600x24
screen -S flux -d -m fluxbox
screen -S x11vnc -d -m x11vnc -nopw -localhost
```
Then you can connect to it through VNC to see what's going on

-----

To run MyRC
```
export DISPLAY=:0
screen -S MyRC -d -m wine AutoHotkey.exe IRCBot.ahk
```

-----

The sandbox plugin allows you to run autohotkey code through the IRC.
There are two known problems with it: It has access to clipboard manipulation, and it has access to A_TimeIdle/Physical.
If these are not big problems for you, go for it.

How to set up the sandbox plugin:

<ol>
    <li>Download the sandbox dll from http://www.golguppe.com/autohotkey/sandbox/ahksandboxansi.dll</li>
    <li>Make double sure you've put the dll in a folder where it will never be moved. Moving it will break all sorts of things, and they aren't always easy to fix.</li>
    <li>Run `wine regsvr32 ahksandboxansi.dll` (or if you're on windows run `regsvr32 ahksandboxansi.dll` as admin)</li>
    <li>Move the sandbox plugin from the disabled folder back into the normal plugin folder</li>
</ol>

-----
-----

Notes:
<ul>
    <li>The first time you run IRCBot, a Settings.ini will be generated. You will need to edit this file with your information.</li>
    <li>The first time the bot receives a PING, it will check the forum's RSS feed, and spam the chat with all 16 messages as the cache has not yet been filled. This may be changed in later updates.</li>
</ul>