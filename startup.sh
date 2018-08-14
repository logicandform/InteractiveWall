#!/bin/bash
# Brings window explorer to the front if its open, otherwise opens it
SERVICE='WindowExplorer'
if ps ax | grep -v grep | grep "${SERVICE}" &> /dev/null; then
    open -a "/Users/irshdc/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqasq/Build/Products/Debug/WindowExplorer.app"
else
    open -n -a "/Users/irshdc/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqasq/Build/Products/Debug/WindowExplorer.app"
fi
