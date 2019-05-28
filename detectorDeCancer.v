`include "tecladoNumerico.v"
`include "bcd7seg.v"

module detectorDeCancer(IO, HEX5, HEX3, HEX2, HEX1, HEX0);

	input [0:11] IO;
	output [0:6] HEX5, HEX3, HEX2, HEX1, HEX0;
	
	reg real [0:6] entradas;
	reg [0] resultado;
	reg int estado;
	
	parameter Pregnancies = 0,
			  Glucose = 1,
			  BloodPressure = 2,
			  SkinThickness = 3,
			  Insulin = 4,
			  BMI = 5,
			  Age = 6,
			  Outcome = 7;

	always @(posedge IO)
		if(IO[11]) begin
			estado = 0
			entradas[0] = 0;
			entradas[1] = 0;
			entradas[2] = 0;
			entradas[3] = 0;
			entradas[4] = 0;
			entradas[5] = 0;
			entradas[6] = 0;
		end
		else if(IO[10])
		begin
			estado = estado + 1;			
			if(estado == Outcome)
			begin
				// Chama a função que calcula.
				
			end
		end
		else			
		begin
			tecladoNumerico tecladoNumerico(IO[0:9], IO[10], entradas[estado], HEX3, HEX2, HEX1, HEX0);			
		end
		
		bcd7seg bcd7seg(estado, HEX5);
	end
	
endmodule