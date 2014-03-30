#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology MACHXO2
set_option -part LCMXO2_7000HE
set_option -package TG144C
set_option -speed_grade -4

#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog 2001 standard option
set_option -vlog_std v2001

#map options
set_option -frequency auto
set_option -maxfan 100
set_option -auto_constrain_io 0
set_option -disable_io_insertion false
set_option -retiming false; set_option -pipe true
set_option -force_gsr false
set_option -compiler_compatible 0
set_option -dup false
set_option -frequency 1
set_option -default_enum_encoding default

#simulation options


#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 1
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0

#-- add_file options
set_option -include_path {X:/ACog/03_Lattice}
add_file -verilog {C:/lscc/diamond/2.1/cae_library/synthesis/verilog/machxo2.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_alu.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_defs.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_id.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_if.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_mem.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_seq.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/acog_wback.v}
add_file -verilog {X:/ACog/03_Lattice/../01_Verilog/aprop.v}
add_file -verilog {X:/ACog/03_Lattice/cog0_mem.v}

#-- top module name
set_option -top_module AProp

#-- set result format/file last
project -result_file {X:/ACog/03_Lattice/AProp/AProp_AProp.edi}

#-- error message log file
project -log_file {AProp_AProp.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run
