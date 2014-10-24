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