# !/bin/sh
export DISPLAY=:0
screen -S MyRC -d -m wine ./AutoHotkey.exe ./bots/IRCBot.ahk
screen -S ForumBot -d -m wine ./AutoHotkey.exe ./bots/ForumBot.ahk
screen -S progbot -d -m wine ./AutoHotkey.exe ./bots/dailyprogbot.ahk
