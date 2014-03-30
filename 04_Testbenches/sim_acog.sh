#!/bin/sh
# run script to simulate ACog
iverilog -I ../01_Verilog -o acog.out -D SIMULATOR=1 tb_acog.v ../01_Verilog/acog*.v 
vvp acog.out