`timescale 1ns/1ps
`define period 10

// iverilog -o tb_i2c_sram_nomaster.vvp tb_i2c_sram_nomaster.v i2c_sram_embedded.v sram.v && vvp tb_i2c_sram_nomaster.vvp
// Test the i2c_sram_embedded without using the master. Master behaviour is plotted in tb.
module tb_i2c_sram_nomaster();
	// sram pins
	tri1 sda;
	reg scl;
	reg [6:0] my_addr;
	wire [7:0] curr_data;
	wire [6:0] rcvd_device_address;
	wire [32:0] state;
	wire rcvd_mode;

	// global pins
	reg [32:0] i;

	// global sda control
	reg sda_to_sram;
	reg wren_sram;
	wire sda_in;

	assign sda_in = !wren_sram ? sda : 1'bZ;
	assign sda = wren_sram ? sda_to_sram : 1'bZ;

	reg[15:0] memory_data_in;


	// slave params to send
	reg[7:0] send_memory_address;
	reg[6:0] send_device_address;
	reg send_device_mode;

	i2c_sram_embedded u_sram (
		.sda(sda),
		.scl(scl),
		.my_addr(my_addr),
		.curr_data(curr_data),
		.rcvd_device_address(rcvd_device_address),
		.state(state),
		.rcvd_mode(rcvd_mode)
	);

	initial begin
		$dumpfile("tb_i2c_sram_nomaster.vcd");
		$dumpvars;

		// set the device address for Device under Test.
		#`period u_sram.reset <= 0;
		#`period u_sram.reset <= 1;

		my_addr = 7'b0111100;

		// command master_to_start
		#`period master_send_start();

		// start sending address 20
		send_device_address = 7'b0111100;
		send_device_mode = 1; // 1 read
		master_send_address_and_mode();

		// send_memory_address = 8'b11001110;
		// send_memory_address = 8'b11111111;
		send_memory_address = 8'b01111100;
		master_send_memory_address();

		// begin receive sequence.
		$display("Begin receiving data.");
		master_begin_receive_part1();
		master_begin_receive_part2();
		master_nack_slave();

		//
		#`period
		#`period
		#`period
		#`period
		#`period
		#`period
		master_send_stop();

		$finish;
	end

	task master_send_address_and_mode;
		begin
			// enable writing to sda
			wren_sram = 1;

			// Send address
			for (i=7; i>0; i=i-1) begin
				#`period
				sda_to_sram =  send_device_address[i-1];
				#`period
				scl = 1;
				#`period
				scl = 0;
			end

			// Send mode 0 (write) and 1 (read)
			#`period
			sda_to_sram =  send_device_mode;
			#`period
			scl = 1;
			#`period
			scl = 0;

			#`period
			sda_to_sram =  0; // regardless of previous mode.

			#`period
			scl = 1;

			#`period
			scl = 0;

			// disable writing to sda
			wren_sram = 0;
		end
	endtask

	task master_send_memory_address;
		begin
			// enable writing to sda
			wren_sram = 1;

			// Send address
			for (i=8; i>0; i=i-1) begin
				#`period
				sda_to_sram =  send_memory_address[i-1];
				#`period
				scl = 1;
				#`period
				scl = 0;
			end
			wren_sram = 0;

			#`period
			sda_to_sram =  0; // regardless of previous mode.

			#`period
			scl = 1;


			// moment where slave acknowledges

			#`period
			scl = 0;

			// disable writing to sda

		end
	endtask

	task master_begin_receive_part1;
		reg [4:0] g;
		begin
			$display("Within master_begin_receive_part1()");
			// enable writing to sda
			wren_sram = 0;
			$display("wren disabled. Master lsitens to SDA.");

			g = 0;
			repeat (8) begin
				#`period
				#`period

				scl = 1;

				#`period

				memory_data_in[g] <= sda_in;
				$display("%d mast_counter: %d sda_in:%b", $time, g, sda_in);
				scl = 0;

				g = g + 1;

			end

			#`period
			wren_sram = 1; // enable writing to sda
			sda_to_sram =  0; // ack sda

			#`period
			scl = 1;

			#`period
			scl = 0;
			// disable writing to sda
			wren_sram = 0;
		end
	endtask

	task master_nack_slave;
		begin
				#`period
				wren_sram = 1; // enable writing to sda
				sda_to_sram =  1; // ack sda

				#`period
				scl = 1;

				// moment where slave acknowledges

				#`period
				scl = 0;

				// disable writing to sda
				wren_sram = 0;
		end
	endtask

	task master_ack_slave;
		begin
				wren_sram = 1; // enable writing to sda
				sda_to_sram =  0; // ack sda

				#`period
				scl = 1;

				// moment where slave acknowledges

				#`period
				scl = 0;

				// disable writing to sda
				wren_sram = 0;
		end
	endtask

	task master_begin_receive_part2;
		reg [3:0] g;
		begin
			$display("Within master_begin_receive_part1()");
			// enable writing to sda
			wren_sram = 0;
			$display("wren disabled. Master lsitens to SDA.");

			g = 8; // para dili mo tugdong ug negative one.
			repeat (8) begin
				#`period
				memory_data_in[g] = sda_in;

				#`period
				scl = 1;

				#`period
				scl = 0;

				g = g + 1;
			end
		end
	endtask

	task master_send_start;
		begin
			sda_to_sram = 1;
			wren_sram = 1;
			scl = 1;
			#`period
			sda_to_sram = 0;
			#`period
			scl = 0;
		end
	endtask

	task master_send_stop;
		begin
			sda_to_sram = 0;
			wren_sram = 1;
			scl = 0;
			#`period
			scl = 1;
			#`period
			sda_to_sram = 1;
		end
	endtask

endmodule
