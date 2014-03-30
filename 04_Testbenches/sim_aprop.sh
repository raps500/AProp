#!/bin/sh
# run script to simulate AProp
iverilog -I ../01_Verilog -o aprop.out -D SIMULATOR=1 tb_aprop.v ../01_Verilog/acog*.v ../01_Verilog/cnt.v ../01_Verilog/hub.v ../01_Verilog/aprop.v
vvp aprop.out