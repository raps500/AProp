/* 
 * ACog - Write back
 * PC & flags are handled here
 * 
 */
`include "acog_defs.v" 

module acog_wback(
	input wire clk_in,
	input wire reset_in,
	input wire [1:0] state_in,
	input wire [31:0] opcode_in,
	input wire d_is_zero_in,
	input wire d_is_one_in,
	input wire execute_in,
	input wire save_c_in,
	input wire save_z_in,
	input wire save_pc_from_s_in,
	input wire save_pc_from_pc_plus_1_in,
	input wire flag_c_in,
	input wire flag_z_in,
	output wire flag_c_o,
	output wire flag_z_o,
	output wire [`MEM_WIDTH-1:0] pc_o,
	output wire [`MEM_WIDTH-1:0] pc_plus_1_o,
	input wire [31:0] s_data_in	
	);
reg flag_c, flag_z;
reg [`MEM_WIDTH-1:0] pc;
wire [`MEM_WIDTH-1:0] pc_plus_1;
assign flag_c_o = flag_c;
assign flag_z_o = flag_z;
assign pc_o = pc;

assign pc_plus_1 = pc + `MEM_WIDTH'h1;
assign pc_plus_1_o =  pc_plus_1;
always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				pc <= 9'h1f4; // start of HUB loader
				flag_c <= 1'b0;
				flag_z <= 1'b0;
			end
		else
		case (state_in)
			`ST_WBACK:
				begin
					if (save_c_in)
						flag_c <= flag_c_in;
					if (save_z_in)
						flag_z <= flag_z_in;
					case (opcode_in[31:26])
						`I_DJNZ:
							if (execute_in & (d_is_one_in))
								pc <= pc_plus_1; // jump not taken
							else
								pc <= s_data_in[`MEM_WIDTH-1:0]; // jump taken
						`I_TJNZ:
							if (execute_in & (!d_is_zero_in))
								pc <= s_data_in[`MEM_WIDTH-1:0]; // jump taken
							else
								pc <= pc_plus_1; // jump not taken
						`I_TJZ:
							if (execute_in & d_is_zero_in)
								pc <= s_data_in[`MEM_WIDTH-1:0]; // jump taken
							else
								pc <= pc_plus_1; // jump not taken
						default:
							if (save_pc_from_pc_plus_1_in)
								pc <= pc_plus_1;
							else
								if (save_pc_from_s_in) // call, jump
									if (opcode_in[`OP_I])
										pc <= opcode_in[`MEM_WIDTH-1:0];
									else
										pc <= s_data_in[`MEM_WIDTH-1:0]; // indirect
					endcase
				end
		endcase
	end
	
	
initial
	begin
		flag_c = 0;
		flag_z = 0;
		pc = 0;
	end
	
endmodule
