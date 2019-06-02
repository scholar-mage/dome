#!/bin/bash
gcc embed.c -o embed -std=c99
./embed ../engine/init.wren initModule ../engine/init.wren.inc
./embed ../engine/input.wren inputModule ../engine/input.wren.inc
./embed ../engine/graphics.wren graphicsModule ../engine/graphics.wren.inc
./embed ../engine/io.wren ioModule ../engine/io.wren.inc
./embed ../engine/audio.wren audioModule ../engine/audio.wren.inc
./embed ../engine/point.wren pointModule ../engine/point.wren.inc
./embed ../engine/game.wren gameModule ../engine/game.wren.inc
