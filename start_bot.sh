# !/bin/sh
export DISPLAY=:0
screen -S MyRC -d -m wine ./AutoHotkey.exe ./IRCBot.ahk
screen -S ForumBot -d -m wine ./AutoHotkey.exe ./ForumBot.ahk
screen -S progbot -d -m wine ./AutoHotkey.exe ./bot/dailyprogbot.ahk
