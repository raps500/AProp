/* 
 * ACog - Sequencer
 * Waits in the Read
 * 
 */
`include "acog_defs.v" 

module acog_seq(
	input wire clk_in,
	input wire reset_in,
	output wire [1:0] state_o,
	input wire [31:0] opcode_in,
	input wire flag_c_in,
	input wire port_pne_pina_in,
	input wire port_peq_pina_in,
	input wire port_pne_pinb_in,
	input wire port_peq_pinb_in,
	input wire port_cnt_eq_d_in,
	input wire execute_in,
	input wire hub_ack_in,
	output reg hub_read_o, // this signal will be asserted on the READ stage
	output reg hub_write_o, // this signal will be asserted on the READ stage
	output reg [1:0] hub_tfr_sz_o
	);
	
reg [1:0] state;
reg read_rdy;
assign state_o = state;

always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				state <= 0;
			end
		else
			begin
				case (state)
					`ST_FETCH: begin state <= state + 2'h1; read_rdy <= 1'b0; end
					`ST_DECODE: state <= state + 2'h1;
					`ST_READ: 
						if (execute_in)
							begin
								read_rdy <= 1'b1;
								if (read_rdy)
									begin
										case (opcode_in[31:26])
										`I_RDBYTE:
											if (hub_ack_in) 
												begin
													state <= state + 2'h1;
													hub_read_o <= 1'b0;
													hub_write_o <= 1'b0;
												end
											else
												begin
													hub_tfr_sz_o <= `SZ_BYTE;
													if (opcode_in[`OP_R])
														hub_read_o <= 1'b1;
													else
														hub_write_o <= 1'b1;
												end
										`I_RDWORD:
											if (hub_ack_in) 
												begin
													state <= state + 2'h1;
													hub_read_o <= 1'b0;
													hub_write_o <= 1'b0;
												end
											else
												begin
													hub_tfr_sz_o <= `SZ_WORD;
													if (opcode_in[`OP_R])
														hub_read_o <= 1'b1;
													else
														hub_write_o <= 1'b1;
												end
										`I_RDLONG:
											if (hub_ack_in) 
												begin
													state <= state + 2'h1;
													hub_read_o <= 1'b0;
													hub_write_o <= 1'b0;
												end
											else
												begin
													hub_tfr_sz_o <= `SZ_LONG;
													if (opcode_in[`OP_R])
														hub_read_o <= 1'b1;
													else
														hub_write_o <= 1'b1;
												end
											`I_WAITCNT: if (port_cnt_eq_d_in) state <= state + 2'h1;
											`I_WAITPEQ: if (flag_c_in & port_peq_pinb_in) state <= state + 2'h1;
														else 
															if ((!flag_c_in) & port_peq_pina_in) state <= state + 2'h1;
											`I_WAITPNE: if (flag_c_in & port_pne_pinb_in) state <= state + 2'h1;
														else 
															if ((!flag_c_in) & port_pne_pina_in) state <= state + 2'h1;
											default: state <= state + 2'h1;
										endcase
									end
								else
									begin
										case (opcode_in[31:26])
											`I_RDBYTE, `I_RDWORD, `I_RDLONG,
											`I_WAITCNT,
											`I_WAITPEQ, 
											`I_WAITPNE: begin end
											default: state <= state + 2'h1;
										endcase
									end
							end
						else
							state <= state + 2'h1; // if we do not execute this opcode...
					`ST_WBACK:state <= state + 2'h1;
				endcase
			end
	end
initial
	begin
		hub_read_o = 0;
		hub_write_o = 0;
		hub_tfr_sz_o = 0;
	end
endmodule
