/* 
 * ACog - Decode unit
 *
 * 
 */
`include "acog_defs.v" 

module acog_id(
	input wire clk_in,
	input wire [1:0] state_in,
	input wire [31:0] opcode_in,
	input wire flag_c_i,
	input wire flag_z_i,
	output reg save_c_o,
	output reg save_z_o,
	output reg save_d_from_alu_o,
	output reg save_d_from_pc_plus_1_o, // CALL, stores PC+1 @ [D]
	output reg save_pc_from_pc_plus_1_o, // not a taken jump or not a jump
	output reg save_pc_from_s_o, // jump, djnz, tjnz, tjz
	output reg [31:0] opcode_o,
	output reg execute_o,
	output reg save_d_from_hub_o,
	output reg [4:0] hub_op_o, 		// HUB opcodes
	output reg [1:0] hub_tfr_sz_o
	);

reg execute;
wire [5:0] opcode;

assign opcode = opcode_in[31:26];
// Condition codes
always @(*)
	begin
		case (opcode_in[`OP_CCCC])
			4'b0000: execute = 1'b0;
			4'b0001: execute = (!flag_z_i) & (!flag_c_i);
			4'b0010: execute = flag_z_i & (!flag_c_i);
			4'b0011: execute = !flag_c_i;
			4'b0100: execute = (!flag_z_i) & flag_c_i;
			4'b0101: execute = !flag_z_i;
			4'b0110: execute = flag_c_i != flag_z_i;
			4'b0111: execute = (!flag_c_i) | (!flag_z_i);
			4'b1000: execute = flag_c_i & flag_z_i;
			4'b1001: execute = flag_c_i == flag_z_i;
			4'b1010: execute = flag_z_i;
			4'b1011: execute = flag_z_i | (!flag_c_i);
			4'b1100: execute = flag_c_i;
			4'b1101: execute = flag_c_i | (!flag_z_i);
			4'b1110: execute = flag_c_i | flag_z_i;
			4'b1111: execute = 1'b1;
		endcase
	end

always @(posedge clk_in)
	begin
		case (state_in)
			`ST_FETCH:
				begin
					save_d_from_alu_o <= 1'b0;
					save_d_from_pc_plus_1_o <= 1'b0;
					save_pc_from_s_o <= 1'b0;
					save_pc_from_pc_plus_1_o <= 1'b0; // NOP
					save_c_o <= 1'b0;
					save_z_o <= 1'b0;
					save_d_from_hub_o <= 1'b0;
				end
			`ST_DECODE:
				begin
					case (opcode)
						`I_HUBOP:
							begin
								save_pc_from_pc_plus_1_o <= 1'b1; 
								save_d_from_hub_o <= opcode_in[`OP_R]; // asserted on reads
								hub_op_o <= { 2'b01, opcode_in[2:0] };
							end
						`I_RDBYTE, `I_RDWORD, `I_RDLONG:
							begin
								save_pc_from_pc_plus_1_o <= 1'b1; 
								save_d_from_hub_o <= opcode_in[`OP_R]; // asserted on reads
								hub_op_o <= { 1'b1, opcode_in[`OP_R], 3'b000 }; // Hub memory opcode, read/*write, the rest is ignored
								hub_tfr_sz_o <= opcode_in[27:26]; // transfer size
							end
							
						`I_JMPRET: 
							if (execute)
								begin
									save_d_from_pc_plus_1_o <= opcode_in[`OP_R];
									save_pc_from_s_o <= 1'b1;
								end
							else
								begin
									save_pc_from_pc_plus_1_o <= 1'b1; // NOP
								end
						`I_DJNZ, `I_TJNZ, `I_TJZ: // handled in wback
							begin end
						default:
							begin
								save_pc_from_pc_plus_1_o <= 1'b1;
							end
					endcase
					if (execute)
						begin
							save_d_from_alu_o <= opcode_in[`OP_R];
							save_c_o <= opcode_in[`OP_C];
							save_z_o <= opcode_in[`OP_Z];
						end
					opcode_o <= opcode_in;
					execute_o <= execute;
				end
		endcase
	end
initial
	begin
		save_d_from_alu_o = 0;
		save_pc_from_s_o = 0;
		save_pc_from_pc_plus_1_o = 0;
		opcode_o = 0;
	end
	
endmodule
