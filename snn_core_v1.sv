module snn_core(start, q_input, addr_input_unit, digit, done, clk, rst_n);

	input start, q_input, clk, rst_n;
	output reg done;
	output reg [9:0] addr_input_unit;
	output reg[7:0] digit;
	logic  clr_n, rhw_result,row_result, w_enable,w_enable_out,en_counter32,en_counter784,en_counter_out32,en_counter_out10;
	logic [7:0] mac_input_1;
	logic [7:0] mac_input_2;
	logic [25:0] mac_output;
	logic [3:0] counter_out_10;
	logic [4:0] counter_32,counter_out_32;
	logic [9:0] counter_784;
	logic [7:0] act_func_result;
	logic [10:0] act_func_addr;
	logic [7:0] q_output,q_output_out;
	logic mac_of, mac_uf;	//delete?
	
	typedef enum reg [3:0] {IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE,
							MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUTPUT_WRITE, DONE} state_t;
	
	state_t state, next_state;
	MAC imac(.a(mac_input_1),.b(mac_input_2),.rst_n(rst_n),.clr_n(clr_n),.acc(mac_output),.clk(clk), .of(mac_of), .uf(mac_uf));
	
	rom #(.ADDR_WIDTH(15),.DATA_WIDTH(8),.file("rom_hidden_weight_contents.txt")) 
		rom_hidden_weight(.addr({counter_32[4:0],counter_784[9:0]}),.clk(clk),.q(rhw_result));

	rom #(.ADDR_WIDTH(9),.DATA_WIDTH(8),.file("rom_output_weight_contents.txt")) 
		rom_output_weight(.addr(counter_out_32[4:0]),.clk(clk),.q(row_result));

	rom #(.ADDR_WIDTH(11),.DATA_WIDTH(8),.file("rom_act_func_lut_contents.txt")) 
		rom_act_func_lut(.addr(act_func_addr),.clk(clk),.q(act_func_result));
	
	ram #(.DATA_WIDTH(8),.ADDR_WIDTH(5),.file("ram_hidden_contents.txt"))
		ram_hidden_unit(.data(act_func_result), .addr(counter_32[4:0]), .we(w_enable), .clk(clk), .q(q_output));
	
	ram #(.DATA_WIDTH(8),.ADDR_WIDTH(4),.file("ram_hidden_contents.txt"))
		ram_output_unit(.data(act_func_result), .addr(counter_out_10[3:0]), .we(w_enable_out), .clk(clk), .q(q_output_out));

	counter #(.bit_length(5))
		counter_5bit(.cnt(counter_32),.clk(clk),.rst_n(rst_n),.en(en_counter32));
	counter #(.bit_length(10))
		counter_10bit(.cnt(counter_784),.clk(clk),.rst_n(rst_n),.en(en_counter784));
	counter #(.bit_length(5))
		counter_out_5bit(.cnt(counter_out_32),.clk(clk),.rst_n(rst_n),.en(en_counter_out32));
	counter #(.bit_length(4))
		counter_out_4bit(.cnt(counter_out_10),.clk(clk),.rst_n(rst_n),.en(en_counter_out10));
	
	always@ (posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
		end	
		else begin
			state <= next_state;
		end
	end
	/*always @(posedge clk, negedge rst_n)			// positive edge triggered async counter

	if (!rst_n)
		cnt<= 5'h0;		//reset counter on active low reset signal
	else 
		cnt <=cnt+1;		// Move to next state

	*/
	always_comb begin		
		clr_n = 1'b0;		//clearing the MAC
		en_counter32=0;
		en_counter784=0;
		en_counter_out32=0;
		w_enable=0;
		digit=8'h0;
		done=0;
	case(state)
	//IDLE: start;
		IDLE: begin
			if(start) begin
				
				next_state = MAC_HIDDEN;
			end
			else
				next_state = IDLE;
		end
		
		MAC_HIDDEN : begin
			clr_n=1'b1;		//deassert clr
			mac_input_1 = {1'b0, {7{q_input}}};
			en_counter784=1;
			if(counter_784 != 10'h30F) begin
				mac_input_2 = rhw_result;
				//counter_784 = counter_784 + 10'h001;
				addr_input_unit <= addr_input_unit + 10'h001;
				next_state = MAC_HIDDEN;
			end
			else begin
				next_state = MAC_HIDDEN_BP1;
			end					
		end
		
		MAC_HIDDEN_BP1: begin
			mac_input_1 = {1'b0, {7{q_input}}};
			mac_input_2 = rhw_result;
			next_state = MAC_HIDDEN_BP2;
		end	
		
		MAC_HIDDEN_BP2: begin
			if((mac_output[25] == 0) &&  |(mac_output[24:17])) begin
				act_func_addr = 11'b01111111111;
			end else if ((mac_output[25] == 1) && !(&(mac_output[24:17]))) begin
				act_func_addr = 11'b10000000000;
			end else begin
				act_func_addr = mac_output[17:7];
			end
			clr_n=1'b0;	//clearing the mac
			next_state = MAC_HIDDEN_WRITE;
		
		end
		
		MAC_HIDDEN_WRITE: begin
			en_counter32=1;
			if(counter_32 != 5'h20) begin
				w_enable = 1'b1;			
				counter_784= 10'h0;
				en_counter32=0;
				
				next_state = MAC_HIDDEN;
			end
			else begin
				w_enable=1'b0;
				counter_32=5'h0;
				next_state = MAC_OUTPUT;
			end
		end
		MAC_OUTPUT:begin 
				mac_input_1=q_output;	//reading RAM_hidden_unit;
				en_counter32=1;
				en_counter_out32=1;	//enabling the 32 bit counter for output. Serves as ROM output weight address also
				if(counter_out_32 != 5'h1F) begin
				mac_input_2=row_result; // reading ROM_output_weight;
				next_state=MAC_OUTPUT;
				end
				else begin
				next_state=MAC_OUTPUT_BP1;
				end
			end
		MAC_OUTPUT_BP1:begin
				mac_input_1=q_output;
				mac_input_2=row_result;
				next_state=MAC_OUTPUT_BP2;
			end
		MAC_OUTPUT_BP2:begin
				if((mac_output[25] == 0) &&  |(mac_output[24:17])) begin
				act_func_addr = 11'b01111111111;
			end else if ((mac_output[25] == 1) && !(&(mac_output[24:17]))) begin
				act_func_addr = 11'b10000000000;
			end else begin
				act_func_addr = mac_output[17:7];
				end
				clr_n=1'b0;
				next_state=MAC_OUTPUT_WRITE;
			end

			MAC_OUTPUT_WRITE:begin
					en_counter_out10=1;
			/*if(counter_out_10 != 4'hA) begin
				w_enable_out = 1'b1;			
				counter_out_32= 5'h0; //used for the next mac output computation
				en_counter_out10=0;
				
				next_state = MAC_OUTPUT;
			end
			else begin
				w_enable=1'b0;
				//counter_32=5'h0;
				next_state = DONE;
			end */
			if(counter_out_10 != 4'hA) begin
				if (digit<act_func_result) begin	
					digit=act_func_result;
				end
				//w_enable_out = 1'b1;			
				counter_out_32= 5'h0;
				en_counter_out10=0;
				
				next_state = MAC_OUTPUT;
			end
			else begin
				//w_enable=1'b0;
				//counter_32=5'h0;
				next_state = DONE;
			end
			end 
		default: begin
			en_counter_out10=0;
			done=1;
			next_state=IDLE;
				end
	endcase
	end
	
endmodule
