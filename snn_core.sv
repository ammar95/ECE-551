module snn_core(start, q_input, addr_input_unit, digit, done, clk, rst_n);

	input start, q_input, clk, rst_n;
	output done;
	output [9:0] addr_input_unit;
	output [3:0] digit;
	logic  clr_n, rhw_result, w_enable;
	logic [7:0] mac_input_1;
	logic [7;0] mac_input_2;
	logic [25:0] mac_output;
	logic [4:0] cnt_hidden;
	logic [3:0] cnt_output;
	logic [9:0] cnt_input;
	logic [7:0] act_func_result;
	logic [10:0] act_func_addr;
	logic [7:0] q_output, zk, digit;
	logic [3:0] cnt_output;
	logic mac_of, mac_uf;	//delete?
	
	typedef enum reg [3:0] {IDLE, MAC_HIDDEN, MAC_HIDDEN_BP1, MAC_HIDDEN_BP2, MAC_HIDDEN_WRITE,
							MAC_OUTPUT, MAC_OUTPUT_BP1, MAC_OUTPUT_BP2, MAC_OUPUT_WRITE, DONE} state_t;
	
	state_t state, next_state;
	MAC imac(.a(mac_input_1),.b(mac_input_2),.rst_n(rst_n),.clr_n(clr_n),.acc(mac_output),.clk(clk), .of(mac_of), .uf(mac_uf));
	
	rom #(.ADDR_WIDTH(15),.DATA_WIDTH(8),.file("rom_hidden_weight_contents.txt")) 
		rom_hidden_weight(.addr({cnt_hidden[4:0],cnt_input[9:0]}),.clk(clk),.q(rhw_result));
		
	rom #(.ADDR_WIDTH(11),.DATA_WIDTH(8),.file("rom_act_func_lut_contents.txt")) 
		rom_act_func_lut(.addr(act_func_addr),.clk(clk),.q(act_func_result));
	
	ram #(.DATA_WIDTH(8),.ADDR_WIDTH(5),file("ram_hidden_contents.txt"))
		ram_hidden_unit(.data(act_func_result), addr(cnt_hidden[4:0]), .we(w_enable), .clk(clk), .q(q_output));

	rom #(.ADDR_WIDTH(9),.DATA_WIDTH(8),.file("rom_output_weight_contents.txt")) 
		rom_hidden_weight(.addr({cnt_output[3:0],cnt_hidden[4:0]}),.clk(clk),.q(row_result));
		
	ram #(.DATA_WIDTH(8),.ADDR_WIDTH(4),file("ram_output_contents.txt"))
		ram_hidden_unit(.data(act_func_result), addr(cnt_output[3:0]), .we(w_enable), .clk(clk), .q(zk));
	

																//TODO: modify rom_act_func_lut;
	always@ (posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
		end	
		else begin
			state <= next_state;
		end
	end
	
	always_comb begin
	// Default ////////////////////////
	clr_n = 1'b1;	
	mac_input_1 = 8'h00;
	w_enable = 1'b0;    //disable ram write	
	digit = 8'h0;	
	///////////////////////////////////
	case(state)
	//IDLE: start;
		IDLE: begin
			if(start) begin
				clr_n = 1'b0;
				cnt_hidden = 5'h0;
				cnt_input = 10'h0;
				addr_input_unit = 10'h000;
				next_state = MAC_HIDDEN;
			end
			else
				next_state = IDLE;
		end
		
		MAC_HIDDEN : begin
			mac_input_1 = {1'b0, 7{q_input}};
			if(cnt_input != 10'h30F) begin					// TODO: adjust later, now 783
				mac_input_2 = rhw_result;
				cnt_input = cnt_input + 10'h001;
				addr_input_unit = addr_input_unit + 10'h001;
				next_state = MAC_HIDDEN;
			end
			else begin
				next_state = MAC_HIDDEN_BP1;
			end					
		end
		
		MAC_HIDDEN_BP1: begin
			mac_input_1 = {1'b0, 7{q_input}};					//mac 783
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
															//TODO: do lut
			next_state = MAC_HIDDEN_WRITE;
		
		end
		
		MAC_HIDDEN_WRITE: begin
			if(cnt_hidden != 5'h20) begin
				w_enable = 1'b1;							//disable somewhere
				cnt_input = 10'h0;
				cnt_hidden = cnt_hidden + 5'h01;
				next_state = MAC_HIDDEN;
			end
			else begin
				w_enable = 1'b0;
				cnt_hidden = 5'h00;
				next_state = MAC_OUTPUT;
			end
			
		end	
		
		MAC_OUTPUT: begin
			mac_input_1 = q_output;
			if(cnt_hidden != 5'h1F) begin				// now 31
				mac_input_2 = row_result;
				cnt_hidden = cnt_hidden + 5'h01;
				next_state = MAC_OUTPUT;
			end
			else begin 
				next_state = MAC_OUTPUT_BP1;
			end
		end	

		MAC_OUTPUT_BP1: begin
			mac_input_1 = q_output;
			mac_input_2 = row_result;
			next_state = MAC_OUTPUT_BP2;
		end

		MAC_OUTPUT_BP2: begin						//TOD0
			next_state = MAC_OUPUT_WRITE;
		end

		MAC_OUPUT_WRITE: begin
			if(cnt_output != 4'hA) BEGIN
				w_enable = 1'b1;
				cnt_hidden = 5'h00;
				cnt_output = cnt_output + 4'h1;
					if(max_value < zk) begin		//find max index.
						digit = cnt_output;
					end
				next_state = MAC_OUTPUT;
			end
			else begin
				w_enable = 1'b0;
				next_state = DONE;
			end	
		end
			
		DONE: begin
			done = 1'b1;
			
		end	
	end
	