#!/bin/bash

cd ~/dev/Tile-Server/bin
screen -d -m -S tiles-1 node www 4100
screen -d -m -S tiles-2 node www 4200
screen -d -m -S tiles-3 node www 4300

cd ~/dev/Caching-Server-UBC
screen -d -m -S caching-server npm start

SERVICE='WindowExplorer'
if !(ps ax | grep -v grep | grep "${SERVICE}" &> /dev/null); then
    open -n -a "/Users/irshdc/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqa$
fi
