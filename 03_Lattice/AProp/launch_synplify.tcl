#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file F:/02_Elektronik/033_AProp/03_Lattice/AProp/launch_synplify.tcl
#-- Written on Wed Mar  5 10:20:21 2014

project -close
set filename "F:/02_Elektronik/033_AProp/03_Lattice/AProp/AProp_syn.prj"
if ([file exists "$filename"]) {
	project -load "$filename"
	project_file -remove *
} else {
	project -new "$filename"
}
set create_new 0

#device options
set_option -technology MACHXO2
set_option -part LCMXO2_7000HE
set_option -package TG144C
set_option -speed_grade -4

if {$create_new == 1} {
#-- add synthesis options
	set_option -symbolic_fsm_compiler true
	set_option -resource_sharing true
	set_option -vlog_std v2001
	set_option -frequency auto
	set_option -maxfan 1000
	set_option -auto_constrain_io 0
	set_option -disable_io_insertion false
	set_option -retiming false; set_option -pipe true
	set_option -force_gsr false
	set_option -compiler_compatible 0
	set_option -dup false
	set_option -frequency 1
	set_option -default_enum_encoding default
	
	
	
	set_option -write_apr_constraint 1
	set_option -fix_gated_and_generated_clocks 1
	set_option -update_models_cp 0
	set_option -resolve_multiple_driver 0
	
}
#-- add_file options
set_option -include_path "F:/02_Elektronik/033_AProp/03_Lattice"
add_file -verilog "C:/lscc/diamond/2.1/cae_library/synthesis/verilog/machxo2.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_alu.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_defs.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_id.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_if.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_mem.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_seq.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/acog_wback.v"
add_file -verilog "F:/02_Elektronik/033_AProp/01_Verilog/aprop.v"
add_file -verilog "F:/02_Elektronik/033_AProp/03_Lattice/cog0_mem.v"
#-- top module name
set_option -top_module AProp
project -result_file {F:/02_Elektronik/033_AProp/03_Lattice/AProp/AProp.edi}
project -save "$filename"
