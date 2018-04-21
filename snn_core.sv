module snn_core(start, q_input, addr_input_unit, digit, done, clk, rst_n);

	input start, q_input, clk, rst_n;
	output done;
	output [9:0] addr_input_unit;
	output [3:0] digit;
	logic  clr_n, rhw_result, w_enable;
	logic [7:0] mac_input_1;
	logic [7;0] mac_input_2;
	logic [25:0] mac_output;
	logic [4:0] counter_32;
	logic [9:0] counter_784;
	logic [7:0] act_func_result;
	logic [10:0] act_func_addr;
	logic [7:0] q_output;
	logic mac_of, mac_uf;	//delete?
	
	typedef enum reg [3:0] {IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE,
							MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUPUT_WRITE, DONE} state_t;
	
	state_t state, next_state;
	MAC imac(.a(mac_input_1),.b(mac_input_2),.rst_n(rst_n),.clr_n(clr_n),.acc(mac_output),.clk(clk), .of(mac_of), .uf(mac_uf));
	
	rom #(.ADDR_WIDTH(15),.DATA_WIDTH(8),.file("rom_hidden_weight_contents.txt")) 
		rom_hidden_weight(.addr({counter_32[4:0],counter_784[9:0]}),.clk(clk),.q(rhw_result));
		
	rom #(.ADDR_WIDTH(11),.DATA_WIDTH(8),.file("rom_act_func_lut_contents.txt")) 
		rom_act_func_lut(.addr(act_func_addr),.clk(clk),.q(act_func_result));
	
	ram #(.DATA_WIDTH(8),.ADDR_WIDTH(5),file("ram_hidden_contents.txt"))
		ram_hidden_unit(.data(act_func_result), addr(counter_32[4:0]), .we(w_enable), .clk(clk), .q(q_output));

	
	always@ (posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
		end	
		else begin
			state <= next_state;
		end
	end
	
	always_comb begin
	clr_n = 1'b1;	

		
		
	case(state)
	//IDLE: start;
		IDLE: begin
			if(start) begin
				clr_n = 1'b0;
				counter_32 = 5'h0;
				counter_784 = 10'h0;
				addr_input_unit = 10'h000;
				next_state = MAC_HIDDEN;
			end
			else
				next_state = IDLE;
		end
		
		MAC_HIDDEN : begin
			mac_input_1 = {1'b0, 7{q_input}};
			w_enable = 1'b0;    //disable ram write	
			if(counter_784 != 10'h310) begin
				mac_input_2 = rhw_result;
				counter_784 = counter_784 + 10'h001;
				addr_input_unit = addr_input_unit + 10'h001;
				next_state = MAC_HIDDEN;
			end
			else begin
				next_state = MAC_HIDDEN_BP1;
			end					
		end
		
		MAC_HIDDEN_BP1: begin
			if((mac_output[25] == 0) &&  |(mac_output[24:17])) begin
				act_func_addr = 11'b01111111111;
			end else if ((mac_output[25] == 1) && !(&(mac_output[24:17]))) begin
				act_func_addr = 11'b10000000000;
			end else begin
				act_func_addr = mac_output[17:7];
			end
			
			next_state = MAC_HIDDEN_BP2;
		end	
		
		MAC_HIDDEN_BP2: begin
			
			next_state = MAC_HIDDEN_WRITE;
		
		end
		
		MAC_HIDDEN_WRITE: begin
			if(counter_32 != 5'h20) begin
				w_enable = 1'b1;			//disable somewhere
				counter_784 = 10'h0;
				next_state = MAC_HIDDEN;
			end
			else begin
				next_state = MAC_OUTPUT;
			end
	
	