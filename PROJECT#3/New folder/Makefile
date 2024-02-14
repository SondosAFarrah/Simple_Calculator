# MPLAB IDE generated this makefile for use with GNU make.
# Project: slave.mcp
# Date: Wed Feb 14 11:48:32 2024

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

slave.cof : slave.o
	$(CC) /p16F877A "slave.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"slave.cof" /M"slave.map" /W /x

slave.o : slave.asm P16F877A.INC LCDIS.INC
	$(AS) /q /p16F877A "slave.asm" /l"slave.lst" /e"slave.err" /d__DEBUG=1

clean : 
	$(CC) "slave.o" "slave.hex" "slave.err" "slave.lst" "slave.cof"

