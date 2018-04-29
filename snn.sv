module snn(clk, sys_rst_n, led, uart_tx, uart_rx);

		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output logic [7:0] led;	// Drives LEDs of DE0 nano board
	
	input uart_rx;
	output uart_tx;
	
	wire [3:0] digit;

	logic rst_n;				 	// Synchronized active low reset
	
	logic uart_rx_ff, uart_rx_synch;
	
	
	wire tx_rdy, rx_rdy, PC_in, PC_out;
	
	logic [7:0] rx_data;
	logic counter_snn_7bit_clr, en_snn_counter98, counter_snn_4bit_clr, en_snn_counter8, en_snn_counter784, counter_snn_10bit_clr;
	logic [6:0] counter_snn_98;
	logic [3:0] counter_snn_8;
	logic [9:0] counter_snn_784;
	
	typedef enum reg [2:0] {IDLE, UART_RX_STATE, UART_RX_STATE_2, SNN_CORE_STATE, DONE} state_t;
	state_t state, next_state;
	/******************************************************
	Reset synchronizer
	******************************************************/
	// rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	/******************************************************
	UART
	******************************************************/
	
	// Declare wires below
	wire tx_start;
	wire [7:0] uart_data;
	logic ram_input_unit_we,ram_input_unit_data,ram_input_unit_out;
	logic [9:0] ram_input_unit_addr;
	logic start;

	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	end
	
	
	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	
	uart_tx my_uart_tx(uart_tx,done,{4'b0,digit[3:0]},tx_rdy,clk,rst_n);			//modify digit

	uart_rx my_uart_rx(uart_rx,rx_rdy,rx_data[7:0],clk,rst_n);
	
	counter #(.bit_length(7))
	counter_snn_7bit(.cnt(counter_snn_98),.clk(clk),.rst_n(rst_n),.en(en_snn_counter98),.clr(counter_snn_7bit_clr));

	counter #(.bit_length(4))
	counter_snn_4bit(.cnt(counter_snn_8),.clk(clk),.rst_n(rst_n),.en(en_snn_counter8),.clr(counter_snn_4bit_clr));

	counter #(.bit_length(10))
	counter_snn_10bit(.cnt(counter_snn_784),.clk(clk),.rst_n(rst_n),.en(en_snn_counter784),.clr(counter_snn_10bit_clr));	

	// TODO: fill in the sample #
	//ram #(.DATA_WIDTH(1),.ADDR_WIDTH(10),.file("ram_input_contents_sample_0.txt")) 
	//	ram_input_unit(ram_input_unit_data,ram_input_unit_addr,ram_input_unit_we,clk,ram_input_unit_out);

	ram #(.DATA_WIDTH(1),.ADDR_WIDTH(10),.file("ram_input_contents_sample_8.txt"))
		ram_output_unit(.data(ram_input_unit_data), .addr(ram_input_unit_addr[9:0]), .we(ram_input_unit_we), .clk(clk), .q(ram_input_unit_out));
	
	snn_core my_snn_core(start, ram_input_unit_out, ram_input_unit_addr, digit, done, clk, rst_n);
	
	// TODO: read only during test
	always_comb begin
		en_snn_counter8 = 0;
		en_snn_counter98 = 0;
		en_snn_counter784 = 0;
		counter_snn_4bit_clr = 0;
		counter_snn_7bit_clr = 0;
		counter_snn_10bit_clr = 0;
		case(state)
			IDLE: begin
				start = 0;
				ram_input_unit_addr = 10'h0;
				if(PC_in) begin
					next_state = UART_RX_STATE;
				end
				else begin
					next_state = IDLE;
				end
			end
			
			UART_RX_STATE: begin
				en_snn_counter98 = 1;
				if(rx_rdy && counter_snn_98 != 7'h62) begin
					next_state = UART_RX_STATE_2;
				end else begin
					counter_snn_7bit_clr = 1;
					counter_snn_4bit_clr = 1;
					en_snn_counter8 = 0;
					en_snn_counter98 = 0;
					ram_input_unit_addr = 10'h0;
					ram_input_unit_we = 0;					
					next_state = SNN_CORE_STATE;
				end
			end
			
			UART_RX_STATE_2: begin
				en_snn_counter8 = 1;
				if(counter_snn_8 != 4'h8) begin
					ram_input_unit_data = rx_data[counter_snn_8];
					ram_input_unit_addr = {counter_snn_98[6:0],counter_snn_8[2:0]};
					ram_input_unit_we = 1'b1;
					next_state = UART_RX_STATE_2;
				end	else begin
					counter_snn_4bit_clr = 1;
					next_state = UART_RX_STATE;
				end				
			end
			
			SNN_CORE_STATE: begin
				start = 1;
				if(!done) begin
					next_state = SNN_CORE_STATE;
				end else begin
					next_state = DONE;
				end
				
			end
			
		    DONE: begin
				if(tx_rdy) begin
				next_state = IDLE;
				end else begin
				next_state = DONE;
				end	
			end
		endcase	
	end
	
	
	
	
	
			
	/******************************************************
	LED
	******************************************************/
	// TODO: edit
	assign	led = (done) ? {4'b0,digit[3:0]} : led;


endmodule