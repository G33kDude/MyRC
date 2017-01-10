# !/bin/sh
export DISPLAY=:0
screen -S geekbot -d -m wine ../AutoHotkey.exe ../bots/GeekBot/GeekBot.ahk
screen -S forumbot -d -m wine ../AutoHotkey.exe ../bots/ForumBot/ForumBot.ahk
screen -S progbot -d -m wine ../AutoHotkey.exe ../bots/DailyProgBot/DailyProgBot.ahk
