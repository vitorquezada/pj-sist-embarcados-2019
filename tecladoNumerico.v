module tecladoNumerico(IO, numero, reset, HEX3, HEX2, HEX1, HEX0);
	
	input [0:9] IO;
	input reset;
	
	output reg [13:0] numero;
	output [0:6] HEX3, HEX2, HEX1, HEX0;
	
	reg [3:0] [0:3] vetorNumero;
	reg [1:0] posicao;
	
	wire clk;
	assign clk = IO[0] | IO[1] | IO[2] | IO[3] | IO[4] | IO[5] | IO[6] | IO[7] | IO[8] | IO[9];

	always @(posedge clk, negedge reset)
		if(reset)
		begin
			numero = 0;
			posicao = 0;
			vetorNumero[0] = 0;
			vetorNumero[1] = 0;
			vetorNumero[2] = 0;
			vetorNumero[3] = 0;
		end
		else
		begin		
			if (IO[0])
			begin
				vetorNumero[posicao] = 0;
			end
			if (IO[1])
			begin
				vetorNumero[posicao] = 1;
			end
			if (IO[2])
			begin
				vetorNumero[posicao] = 2;
			end
			if (IO[3])
			begin
				vetorNumero[posicao] = 3;
			end
			if (IO[4])
			begin
				vetorNumero[posicao] = 4;
			end
			if (IO[5])
			begin
				vetorNumero[posicao] = 5;
			end
			if (IO[6])
			begin
				vetorNumero[posicao] = 6;
			end
			if (IO[7])
			begin
				vetorNumero[posicao] = 7;
			end
			if (IO[8])
			begin
				vetorNumero[posicao] = 8;
			end
			if (IO[9])
			begin
				vetorNumero[posicao] = 9;
			end
			
			posicao = posicao + 1;
			numero = vetorNumero[0] + vetorNumero[1] * 10 + vetorNumero[2]*100 + vetorNumero[3] * 1000;
		end
		
		bcd7seg digit3 (vetorNumero[3], HEX3);
		bcd7seg digit2 (vetorNumero[2], HEX2);
		bcd7seg digit1 (vetorNumero[1], HEX1);
		bcd7seg digit0 (vetorNumero[0], HEX0);
	end

endmodule

module bcd7seg (bcd, display);
	input [3:0] bcd;
	output [0:6] display;

	reg [0:6] display;

	/*
	 *       0  
	 *      ---  
	 *     |   |
	 *    5|   |1
	 *     | 6 |
	 *      ---  
	 *     |   |
	 *    4|   |2
	 *     |   |
	 *      ---  
	 *       3  
	 */
	always @ (bcd)
		case (bcd)
			4'h0: display = 7'b0000001;
			4'h1: display = 7'b1001111;
			4'h2: display = 7'b0010010;
			4'h3: display = 7'b0000110;
			4'h4: display = 7'b1001100;
			4'h5: display = 7'b0100100;
			4'h6: display = 7'b1100000;
			4'h7: display = 7'b0001111;
			4'h8: display = 7'b0000000;
			4'h9: display = 7'b0001100;
			default: display = 7'b0000000;
		endcase
endmodule
