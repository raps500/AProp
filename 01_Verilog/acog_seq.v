/* 
 * ACog - Sequencer
 * Waits in the Read
 * 
 */
`include "acog_defs.v" 

module acog_seq(
	input wire 			clk_in,
	input wire 			reset_in,
	output wire [1:0] state_o,
	input wire [31:0] opcode_in,
	input wire 			flag_c_in,
	input wire 			port_pne_pina_in,
	input wire 			port_peq_pina_in,
	input wire 			port_pne_pinb_in,
	input wire 			port_peq_pinb_in,
	input wire 			port_cnt_eq_d_in,
	input wire 			execute_in,
	input wire 			hub_ack_in,
	input wire[4:0] 	hub_op_in,
	output wire			hub_data_rdy_o // this signal will be asserted on the READ stage after D&S are read
	);
	
reg [1:0] state;
reg read_rdy, data_to_hub_rdy;

assign state_o = state;
assign hub_data_rdy_o = data_to_hub_rdy;

always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				state <= 0;
			end
		else
			begin
				case (state)
					`ST_FETCH: begin state <= state + 2'h1; end
					`ST_DECODE: state <= state + 2'h1;
					`ST_READ: 
						begin
							if (hub_ack_in) 
								begin
									state <= state + 2'h1;
									read_rdy <= 1'b0;
									data_to_hub_rdy <= 1'b0;
								end
							else
							if (execute_in)
								begin
									if (read_rdy)
										begin
											case (opcode_in[31:26])
												`I_RDBYTE, `I_RDWORD, `I_RDLONG:
													begin end
												`I_WAITCNT: if (port_cnt_eq_d_in) state <= state + 2'h1;
												`I_WAITPEQ: if (flag_c_in & port_peq_pinb_in) state <= state + 2'h1;
														else 
																if ((!flag_c_in) & port_peq_pina_in) state <= state + 2'h1;
												`I_WAITPNE: if (flag_c_in & port_pne_pinb_in) state <= state + 2'h1;
															else 
																if ((!flag_c_in) & port_pne_pina_in) state <= state + 2'h1;
												default: 
													begin
														state <= state + 2'h1;
														read_rdy <= 1'b0;
													end
											endcase
										end
									else // if (read_rdy) : not yet ready, set ready
										begin
											case (opcode_in[31:26])
												`I_RDBYTE, `I_RDWORD, `I_RDLONG:
													begin
														read_rdy <= 1'b1;
														data_to_hub_rdy <= 1'b1;
													end
												`I_WAITCNT,
												`I_WAITPEQ, 
												`I_WAITPNE: read_rdy <= 1'b1;
												default: state <= state + 2'h1;
											endcase
										end
								end
							else // if (execute_in)
								state <= state + 2'h1; // if we do not execute this opcode...
						end
					`ST_WBACK:state <= state + 2'h1;
				endcase
			end
	end
initial
	begin
		
	end
endmodule
