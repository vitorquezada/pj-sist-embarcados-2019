`include "detectorDeDiabetes.v"

module tb;

	reg [0:9] SW;
	reg [0:1] KEY;//[0] - Clear / [1] - Proximo
	reg ADC_CLK_10;
	wire [0:6] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	wire [0:9] LEDR;

	task preencher;
		input [3:0] num;

		begin
			if(num >= 0 && num <= 9)
			begin
				SW[num] = 1;
				#10;
				SW[num] = 0;
				#10;
			end
		end
	endtask
	
	task proximo;
	
		begin
			KEY[1] = 1;
			#10;
			KEY[1] = 0;
			#10;
		end
	endtask
	
	task clear;
	
		begin
			KEY[0] = 1;
			#10;
			KEY[0] = 0;
			#10;
		end
	endtask

	detectorDeDiabetes detectorDeDiabetes(.SW(SW), .KEY(KEY), .ADC_CLK_10(ADC_CLK_10), .HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0), .LEDR(LEDR));	

	initial
	begin
		$display("iniciou TB");
		preencher(6);
		proximo();
		preencher(1);
		preencher(4);
		preencher(8);
		proximo();
		preencher(7);
		preencher(2);
		proximo();
		preencher(3);
		preencher(5);
		proximo();
		preencher(0);
		proximo();
		preencher(3);
		preencher(7);
		proximo();
		preencher(6);
		preencher(2);
		preencher(7);
		proximo();
		preencher(5);
		preencher(0);
		proximo();
		$display("Terminou TB");
	end
	
	always
		#1 ADC_CLK_10 = ~ADC_CLK_10;
endmodule