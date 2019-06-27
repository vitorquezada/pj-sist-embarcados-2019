module detectorDeDiabetes(SW, KEY, ADC_CLK_10, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR);
	input [0:9] SW;
	input [0:1] KEY;//[0] - Clear / [1] - Proximo
	input ADC_CLK_10;
	output [0:6] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	output [0:9] LEDR;

	reg [0:9] SW_corrigido;
	reg clear, prox;
	reg [12:0] slow_clk;
	
	reg digitou;
	
	assign LEDR = SW_corrigido;	
	
	parameter QtdBitsDecimais = 16; // Q16.16
	parameter N = 5,
			  Glucose = 0,
			  BloodPressure = 1,
			  SkinThickness = 2,
			  Insulin = 3,
			  BMI = 4,
			  Age = 5,
			  Outcome = 6;

	reg [4:0] estado;
	reg [4:0] resultado;
	reg [3:0] numeroVetorizado [0:N] [0:3];
	reg [1:0] posicao;
	reg [31:0] entradas [0:N];
	
	reg [31:0] i, j;

	task tecladoNumerico;
		input [0:9] vetorEntradas;

		begin
			if (vetorEntradas[0])
				numeroVetorizado[estado][posicao] = 0;
			else if(vetorEntradas[1])
				numeroVetorizado[estado][posicao] = 1;
			else if(vetorEntradas[2])
				numeroVetorizado[estado][posicao] = 2;
			else if(vetorEntradas[3])
				numeroVetorizado[estado][posicao] = 3;
			else if(vetorEntradas[4])
				numeroVetorizado[estado][posicao] = 4;
			else if(vetorEntradas[5])
				numeroVetorizado[estado][posicao] = 5;
			else if(vetorEntradas[6])
				numeroVetorizado[estado][posicao] = 6;
			else if(vetorEntradas[7])
				numeroVetorizado[estado][posicao] = 7;
			else if(vetorEntradas[8])
				numeroVetorizado[estado][posicao] = 8;
			else if(vetorEntradas[9])
				numeroVetorizado[estado][posicao] = 9;
			
			posicao = posicao + 1;
			if(posicao == 5)
			begin
				posicao = 0;
			end
			
			entradas[estado] = 0;
			j = 1;
			for(i = 0; i < 4; i = i + 1)
			begin
			    entradas[estado] = entradas[estado] + (numeroVetorizado[estado][i] * j);
			    j = j * 10;
			end
		end
	endtask
	
	//########################################################################################
	task mlp;

		parameter signed [3:0] NEURONIOS = 4'b0111; /* 7 neuronios camada intermediaria */
		reg signed [4:0] i;
		reg signed [32:0] f[0:N];
		reg signed [32:0] y;
		reg signed [15:0] w [0:N][0:NEURONIOS]; /* camada intermediaria */
		reg signed [15:0] v [0:NEURONIOS]; /* camada saida */

		parameter signed [15:0] zero= 16'b00000000_00000000;
		parameter signed [15:0] um= 16'b00000001_00000000;

		begin

			i = 4'b0000;
			
			/* CAMADA INTERMEDIARIA */
			for (i = 0; i < (NEURONIOS - 1); i = i + 1)
			begin
				w[0][i] = 16'b00000000_00010001;			
				w[1][i] = 16'b00000000_00010001;			
				w[2][i] = 16'b00000000_00010001;
				w[3][i] = 16'b00000000_00010001; 
				w[4][i] = 16'b00000000_00010001;
				w[5][i] = 16'b00000000_00010001;
				w[6][i] = 16'b00000000_00010001;
				v[i] = 16'b00000000_00010001;
				/* Soma */
				f[i]  =   entradas[0]*w[0][i] +
					entradas[1]*w[1][i] +
					entradas[2]*w[2][i] +
					entradas[3]*w[3][i] +
					entradas[4]*w[4][i] +
					entradas[5]*w[5][i]+
					w[6][i]; //bias

				/* Relu com limite superior*/
				if(f[i] > um)
					f[i] = 16'b00000001_00000000;//um;
				else if(f[i] < zero)
					f[i] = 16'b00000000_00000000;//zero;
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
				resultado = 4;              //y = 3;
			else if(y > 32'b0000000000000000_1000000000000000) // 0.6 > y > 0.5
				resultado = 5;              //y = 2;
			else if(y > 32'b0000000000000000_0110011001100110) // 0.5 > y > 0.4
				resultado = 6;              //y = 1;
			else                        //y < 0.4
				resultado = 2;              //y = 0;
		end
	endtask
	//########################################################################################
	
	task taskClear;
		begin
			estado = 0;
			resultado = 0;
			posicao = 0;
			for (i = 0; i <= 6; i = i + 1)
			begin
				entradas[i] = 0;
				for(j = 0; j <= 3; j = j + 1)  numeroVetorizado[i][j] = 0;
			end
		end
	endtask
	
	initial
	begin
		taskClear();
	end

	always @(posedge ADC_CLK_10)
	begin
		slow_clk = slow_clk + 1'b1;
		if(slow_clk == 0)
		begin
			SW_corrigido = SW;
			clear = KEY[0];
			prox = KEY[1];
			digitou = SW[0] || SW[1] || SW[2] || SW[3] || SW[4] || SW[5] || SW[6] || SW[7] || SW[8] || SW[9] || ~KEY[0] || ~KEY[1];
		end
	end
	
	always @(posedge digitou)
	begin
		if (~clear)
		begin
			taskClear();
		end
		else if (~prox)
		begin
			if (estado == Outcome)
			begin
				taskClear();
			end
			else
			begin
				estado = estado + 1;
				if(estado == Outcome)
				begin
					for(i = 0; i < N; i = i + 1)
					begin
						entradas[i] = entradas[i] << QtdBitsDecimais;
					end

					mlp(); //########################################################

					numeroVetorizado[estado][3] = 0;
					numeroVetorizado[estado][2] = 0;
					numeroVetorizado[estado][1] = 0;
					numeroVetorizado[estado][0] = resultado;
				end				
			end
		end
		else
		begin
			tecladoNumerico(SW_corrigido);
		end
	end

	bcd7seg digit5 (estado, HEX5);
	bcd7seg digit4 (4'h0, HEX4);
	bcd7seg digit3 (numeroVetorizado[estado][3], HEX3);
	bcd7seg digit2 (numeroVetorizado[estado][2], HEX2);
	bcd7seg digit1 (numeroVetorizado[estado][1], HEX1);
	bcd7seg digit0 (numeroVetorizado[estado][0], HEX0);

endmodule