`include "tecladoNumerico.v"
`include "bcd7seg.v"

module detectorDeCancer(IO, HEX5, HEX3, HEX2, HEX1, HEX0);

	input [0:11] IO;
	output [0:6] HEX5, HEX3, HEX2, HEX1, HEX0;
	
	reg real entradas [0:6];
	reg [0:0] resultado;
	reg [3:0] estado;


	parameter Pregnancies = 0,
			  Glucose = 1,
			  BloodPressure = 2,
			  SkinThickness = 3,
			  Insulin = 4,
			  BMI = 5,
			  Age = 6,
			  Outcome = 7;

	always @(posedge IO)
		// Reset
		if(IO[11] || (IO[10] && estado == Outcome))
		begin
			estado = 0;
			resultado = 0;
			entradas[0] = 0;
			entradas[1] = 0;
			entradas[2] = 0;
			entradas[3] = 0;
			entradas[4] = 0;
			entradas[5] = 0;
			entradas[6] = 0;
		end
		// Próximo
		else if(IO[10])
		begin
			estado = estado + 1;			
			if(estado == Outcome)
			begin
				// Chama a função que calcula.
				// resultado = funcao
				bcd7seg digito1(resultado, HEX3);
				bcd7seg digito2(resultado, HEX2);
				bcd7seg digito1(resultado, HEX1);
				bcd7seg digito0(resultado, HEX0);
			end
		end
		// Digitando o número.
		else
			tecladoNumerico TN(IO[0:9], IO[10], entradas[estado], HEX3, HEX2, HEX1, HEX0);
		
		bcd7seg digito4(estado, HEX5);	
endmodule