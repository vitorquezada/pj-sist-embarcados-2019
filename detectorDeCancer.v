`include "bcd7seg.v"

module detectorDeCancer(IO, clear, prox, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
	input [0:9] IO;
	input clear, prox;
	output [0:6] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	parameter QtdBitsDecimais = 16, // Q16.16
			  N = 6, /* numero entradas */
			  Pregnancies = 0,
			  Glucose = 1,
			  BloodPressure = 2,
			  SkinThickness = 3,
			  Insulin = 4,
			  BMI = 5,
			  Age = 6,
			  Outcome = 7;

	reg [3:0] estado;	
	reg [4:0] resultado;
	reg [3:0] numeroVetorizado [0:3] [0:N];
	reg [1:0] posicao;
	reg signed [31:0] [0:N] entradas;
	
	reg [31:0] i, j;

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
	
	task mlp;
		input signed [15:0][0:N] x;
		output reg signed [4:0] result;

		parameter signed [3:0] NEURONIOS = 4'b0111; /* 7 neuronios camada intermediaria */
		reg signed [3:0] i;
		reg signed [31:0] f[0:N];
		reg signed [31:0] y;
		reg signed [15:0] w [0:N][0:NEURONIOS]; /* camada intermediaria */
		reg signed [15:0] v [0:NEURONIOS]; /* camada saida */

		parameter signed [15:0] zero= 16'b00000000_00000000;
		parameter signed [15:0] um= 16'b00000111_00000000;

		begin

			i = 4'b0000;

			x[0] = 16'b00000000_00010001; 
			w[0][i] = 16'b00000000_00010001;
			x[1] = 16'b00000000_00010001; 
			w[1][i] = 16'b00000000_00010001;
			x[2] = 16'b00000000_00010001; 
			w[2][i] = 16'b00000000_00010001;
			x[3] = 16'b00000000_00010001; 
			w[3][i] = 16'b00000000_00010001;
			x[4] = 16'b00000000_00010001; 
			w[4][i] = 16'b00000000_00010001;
			x[5] = 16'b00000000_00010001; 
			w[5][i] = 16'b00000000_00010001;
			w[6][i] = 16'b00000000_00010001;
			v[i] = 16'b00000000_00010001;

			/* CAMADA INTERMEDIARIA */
			for (i = 0; i < (NEURONIOS - 1); i = i + 1) begin
			/* Soma */
			f[i]  =   x[0]*w[0][i] +
				x[1]*w[1][i] +
				x[2]*w[2][i] +
				x[3]*w[3][i] +
				x[4]*w[4][i] +
				x[5]*w[5][i]+
				w[6][i]; //bias

			/* Relu com limite superior*/
			if(f[i] > um)
			f[i] = um;
			else if(f[i] < zero)
			f[i] = zero;
				
			end

			/* CAMADA SAIDA */
			y = f[0][23:8]*v[0]+
			f[1][23:8]*v[1]+
			f[2][23:8]*v[2]+
			f[3][23:8]*v[3]+
			f[4][23:8]*v[4]+
			f[5][23:8]*v[5]+
			f[6][23:8]*v[6]+
			v[7];

			if(     y > 32'b0000000000000000_1001100110011001)      //y > 0.6
			result = 3;              //y = 3;
			else if(y > 32'b0000000000000000_1000000000000000) // 0.6 > y > 0.5
			result = 2;              //y = 2;
			else if(y > 32'b0000000000000000_0110011001100110) // 0.5 > y > 0.4
			result = 1;              //y = 1;
			else                        //y < 0.4
			result = 0;              //y = 0;

			$display("%f", result);
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
				for(i = 0; i < N; i = i + 1)
					entradas[i] = entradas[i] << QtdBitsDecimais;

				mlp(entradas, resultado);

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
