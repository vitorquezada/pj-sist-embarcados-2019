module tecladoNumerico(
	input [0:9]  IO,
	input        reset,
	output real  numero,
	output [0:6] HEX3,
				 HEX2,
				 HEX1,
				 HEX0);
	
	reg [3:0] vetorNumero [0:3];
	reg [1:0] posicao;
	
	always @(posedge IO or posedge reset)
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
			case (1)
				IO[0]: vetorNumero[posicao] = 0;
				IO[1]: vetorNumero[posicao] = 1;
				IO[2]: vetorNumero[posicao] = 2;
				IO[3]: vetorNumero[posicao] = 3;
				IO[4]: vetorNumero[posicao] = 4;
				IO[5]: vetorNumero[posicao] = 5;
				IO[6]: vetorNumero[posicao] = 6;
				IO[7]: vetorNumero[posicao] = 7;
				IO[8]: vetorNumero[posicao] = 8;
				IO[9]: vetorNumero[posicao] = 9;
			endcase
			
			posicao = posicao + 1;
			numero = vetorNumero[0] + vetorNumero[1] * 10 + vetorNumero[2]*100 + vetorNumero[3] * 1000;
		end
		
		bcd7seg digit3(vetorNumero[3], HEX3);
		bcd7seg digit2(vetorNumero[2], HEX2);
		bcd7seg digit1(vetorNumero[1], HEX1);
		bcd7seg digit0(vetorNumero[0], HEX0);
endmodule