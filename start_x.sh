export DISPLAY=:0
screen -S xvfb -d -m Xvfb -screen 0 800x600x24
screen -S flux -d -m fluxbox
screen -S x11vnc -d -m x11vnc -nopw -forever -xkb -skip_keycodes 187,188 -localhost
#x11vnc -forever -usepw -auth ~/$1 -display $1
