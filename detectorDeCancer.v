`include "bcd7seg.v"

module detectorDeCancer(IO, clear, prox, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
	input [0:9] IO;
	input clear, prox;
	output [0:6] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	
	reg [3:0] estado, resultado;	
	reg [3:0] numeroVetorizado [0:3] [0:6];
	reg [1:0] posicao;
	reg real entradas [0:6];
	
	integer i, j;

	parameter Pregnancies = 0,
			  Glucose = 1,
			  BloodPressure = 2,
			  SkinThickness = 3,
			  Insulin = 4,
			  BMI = 5,
			  Age = 6,
			  Outcome = 7;

	task tecladoNumerico;
		input [0:9] IO;

		begin
			case (1)
				IO[0]: numeroVetorizado[estado][posicao] = 0;
				IO[1]: numeroVetorizado[estado][posicao] = 1;
				IO[2]: numeroVetorizado[estado][posicao] = 2;
				IO[3]: numeroVetorizado[estado][posicao] = 3;
				IO[4]: numeroVetorizado[estado][posicao] = 4;
				IO[5]: numeroVetorizado[estado][posicao] = 5;
				IO[6]: numeroVetorizado[estado][posicao] = 6;
				IO[7]: numeroVetorizado[estado][posicao] = 7;
				IO[8]: numeroVetorizado[estado][posicao] = 8;
				IO[9]: numeroVetorizado[estado][posicao] = 9;
			endcase
			
			entradas[estado] = 0;
			j = 1;
			for(i = 0; i < posicao; i = i + 1)
			begin
			    entradas[estado] = entradas[estado] + (numeroVetorizado[estado][i] * j);
			    j = j * 10;
			end
			posicao = posicao + 1;
			$display("Entrada do estado: %.2f", entradas[estado]);
		end
	endtask
	
	assign digitou = IO[0] || IO[1] || IO[2] || IO[3] || IO[4] || IO[5] || IO[6] || IO[7] || IO[8] || IO[9];

	always @(posedge digitou or posedge clear or posedge prox)
	begin	
		if (clear || (prox && estado == Outcome))
		begin
			$display("Clear");
			estado = 0;
			resultado = 0;
			posicao = 0;
			for (i = 0; i <= 6; i = i + 1)
			begin
				entradas[i] = 0;
				for(j = 0; j <= 3; j = j + 1) numeroVetorizado[i][j] = 0;
			end
		end
		else if (prox)
		begin
			estado = estado + 1;			
			$display("Estado atual: %d", estado);
			if(estado == Outcome)
			begin
				// Chama a função que calcula.
			    // resultado = funcao
				numeroVetorizado[estado][3] = 0;
				numeroVetorizado[estado][2] = 0;
				numeroVetorizado[estado][1] = 0;
				numeroVetorizado[estado][3] = resultado;
			end
		end
		else
		begin
			tecladoNumerico(IO);
			$display("Entrada do estado: %f", entradas[estado]);
		end
	end

	bcd7seg digit5 (estado, HEX5);
	bcd7seg digit4 (4'h0, HEX4);
	bcd7seg digit3 (numeroVetorizado[estado][3], HEX3);
	bcd7seg digit2 (numeroVetorizado[estado][2], HEX2);
	bcd7seg digit1 (numeroVetorizado[estado][1], HEX1);
	bcd7seg digit0 (numeroVetorizado[estado][0], HEX0);

endmodule
