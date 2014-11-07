export DISPLAY=:0
screen -S xvfb -d -m Xvfb -screen 0 800x600x24
screen -S flux -d -m fluxbox
screen -S x11vnc -d -m x11vnc -nopw -forever
