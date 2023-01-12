## TEAMS MEMBERS
GROUP 1
Bingrun Du(999009210)
Cheng Yang(999009475)
Junchang Lv(999008865) 
Yaotong Yuan(999009517)
Yingjie Mao(999013345)


## HOW TO BUILD THE DEMO

to run the program simply execute:

using command line in windows
cd <filepath> 
rgbasm -L -o main.o main.asm
rgblink -o main.gb main.o
rgbfix -v -p 0xFF main.gb
// generate a sym file for ROM to debug
rgblink -n main.sym main.o

using cmake in linux
cd <filepath> 
make
// clean .o and .gb file to regenerate
make clean

## HOW TO RUN THE DEMO
open main.gb in bgb emulator

## DESCRIPTION OF THE PROJECT

_SCENCE1_
digits contains time data
**using**
object moving

_SCENCE2_
mask in COVID-19 situation
**using**
BG or object palette manipulation

_SCENCE3_
peaople fight against virus
**using**
scrolling background layer
non-trivially moving objects
VBlank interrupt

