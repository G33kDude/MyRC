#!/bin/sh

# Occasionally screen forgets about its running instances.
# By telling sending it a CHLD signal, it'll recheck for instances and fix itself.
# This will *NOT* actually kill screen.

killall -s CHLD screen