`include "bcd7seg.v"

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
	parameter N = 8, // Número de entradas
				  Pregnancies = 0,
				  Glucose = 1,
				  BloodPressure = 2,
				  SkinThickness = 3,
				  Insulin = 4,
				  BMI = 5,
				  DiabetesPedigree = 6,
				  Age = 7,
				  Outcome = 8;
				  

	reg [5:0] estado;
	reg [5:0] resultado;
	reg [3:0] numeroVetorizado [0:N] [0:3];
	reg signed [31:0] entradas [0:N];
	reg signed [63:0] entradasMultiplicacao [0:N];
	
	parameter [3:0] NEURONIOS = 4'b1000; /* 8 neuronios camada intermediaria */
	reg signed [31:0] w [0:N][0:NEURONIOS]; /* camada intermediaria */
	reg signed [31:0] v [0:NEURONIOS]; /* camada saida */
	
	reg [31:0] i, j;

	task tecladoNumerico;
		input [0:9] vetorEntradas;

		begin
			numeroVetorizado[estado][3] = numeroVetorizado[estado][2];
			numeroVetorizado[estado][2] = numeroVetorizado[estado][1];
			numeroVetorizado[estado][1] = numeroVetorizado[estado][0];
			
			if (vetorEntradas[0])
				numeroVetorizado[estado][0] = 0;
			else if(vetorEntradas[1])
				numeroVetorizado[estado][0] = 1;
			else if(vetorEntradas[2])
				numeroVetorizado[estado][0] = 2;
			else if(vetorEntradas[3])
				numeroVetorizado[estado][0] = 3;
			else if(vetorEntradas[4])
				numeroVetorizado[estado][0] = 4;
			else if(vetorEntradas[5])
				numeroVetorizado[estado][0] = 5;
			else if(vetorEntradas[6])
				numeroVetorizado[estado][0] = 6;
			else if(vetorEntradas[7])
				numeroVetorizado[estado][0] = 7;
			else if(vetorEntradas[8])
				numeroVetorizado[estado][0] = 8;
			else if(vetorEntradas[9])
				numeroVetorizado[estado][0] = 9;
			
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
	
		reg signed [63:0] f[0:N];
		reg signed [63:0] y;
		

		parameter signed [63:0] zero = 0;
		parameter signed [63:0] um = 64'b00000000000000000000000000000001_00000000000000000000000000000000;

		begin
			//Normalização simples:
			
			entradasMultiplicacao[0] = entradas[0]*32'b0000000000000000_0000110011001100;  // 1 / 20
			entradasMultiplicacao[1] = entradas[1]*32'b0000000000000000_0000000101000111;  // 1 / 200
			entradasMultiplicacao[2] = entradas[2]*32'b0000000000000000_0000000111111000;  // 1 / 130
			entradasMultiplicacao[3] = entradas[3]*32'b0000000000000000_0000001010001111;  // 1 / 100
			entradasMultiplicacao[4] = entradas[4]*32'b0000000000000000_0000000001001000;  // 1 / 900
			entradasMultiplicacao[5] = entradas[5]*32'b0000000000000000_0000001100110011;  // 1 / 80
			entradasMultiplicacao[6] = entradas[6]*32'b0000000000000000_0000000000010101;  // 1 / 3000
			entradasMultiplicacao[7] = entradas[7]*32'b0000000000000000_0000001010001111;  // 1 / 100

			entradas[0] = entradasMultiplicacao[0][47:16];
			entradas[1] = entradasMultiplicacao[1][47:16];
			entradas[2] = entradasMultiplicacao[2][47:16];
			entradas[3] = entradasMultiplicacao[3][47:16];
			entradas[4] = entradasMultiplicacao[4][47:16];
			entradas[5] = entradasMultiplicacao[5][47:16];
			entradas[6] = entradasMultiplicacao[6][47:16];
			entradas[7] = entradasMultiplicacao[7][47:16];
			
			//Fim normalização simples
			
			/* CAMADA INTERMEDIARIA */
			for (i = 0; i < NEURONIOS; i = i + 1)
			begin
				
				f[i] = zero;
				/* Soma */
				for(j = 0; j < N; j = j + 1)
				begin
					f[i] = f[i] + (entradas[j] * w[j][i]);
				end
				f[i] = f[i] + (um * w[N][i]); //bias
				
				/* Relu com limite superior*/
				if($signed(f[i]) > $signed(um))
					f[i] = um;
				else if($signed(f[i]) < $signed(zero))
					f[i] = zero;
			end

			/* CAMADA SAIDA */
			y = f[0][47:16]*v[0]+
				 f[1][47:16]*v[1]+
				 f[2][47:16]*v[2]+
				 f[3][47:16]*v[3]+
				 f[4][47:16]*v[4]+
				 f[5][47:16]*v[5]+
				 f[6][47:16]*v[6]+
				 f[7][47:16]*v[7]+
				 um*v[8];
				 
			if($signed(y) > $signed(64'b00000000000000000000000000000000_10011001100110010000000000000000))      //y > 0.6
				resultado = 3;              //y = 3;
			else if($signed(y) > $signed(64'b00000000000000000000000000000000_10000000000000000000000000000000)) // 0.6 > y > 0.5
				resultado = 2;              //y = 2;
			else if($signed(y) > $signed(64'b00000000000000000000000000000000_01100110011001100000000000000000)) // 0.5 > y > 0.4
				resultado = 1;              //y = 1;
			else                        //y < 0.4
				resultado = 0;              //y = 0;
		end
	endtask
	//########################################################################################
	
	task taskClear;
		begin
			estado = 0;
			resultado = 0;
			for (i = 0; i < N; i = i + 1)
			begin
				entradas[i] = 0;
				for(j = 0; j <= 3; j = j + 1)  numeroVetorizado[i][j] = 0;
			end
		end
	endtask
	
	initial
	begin
	
		$display("Iniciou");
		taskClear();
		
		//first_layer_weights 2000 iterations
		w[0][0] = -32'b0000000000000000_1110101111110011;  //0.92168313
		w[0][1] = 32'b0000000000000000_1000010010111100;  //0.5185032
		w[0][2] = -32'b0000000000000000_1001110001001000;  //0.6104816
		w[0][3] = -32'b0000000000000000_1011011011010100;  //0.7141755
		w[0][4] = 32'b0000000000000000_0011010101100000;  //0.208506
		w[0][5] = 32'b0000000000000000_0110001111011011;  //0.39006162
		w[0][6] = 32'b0000000000000000_0111101010001111;  //0.47875044
		w[0][7] = -32'b0000000000000000_0111100000101110;  //0.46945316
		w[1][0] = -32'b0000000000000000_1100010011111111;  //0.7695224
		w[1][1] = 32'b0000000000000000_1110001111010000;  //0.8899026
		w[1][2] = -32'b0000000000000000_0101101111100100;  //0.35895374
		w[1][3] = -32'b0000000000000000_0001110101110001;  //0.11501834
		w[1][4] = 32'b0000000000000001_0011010000000010;  //1.2031652
		w[1][5] = 32'b0000000000000001_0000111111000111;  //1.0616317
		w[1][6] = -32'b0000000000000000_1100000111101000;  //0.7574511
		w[1][7] = -32'b0000000000000000_0011010011100001;  //0.2065591
		w[2][0] = 32'b0000000000000000_0011101110101101;  //0.23311122
		w[2][1] = -32'b0000000000000000_0100100111011011;  //0.28850433
		w[2][2] = -32'b0000000000000000_0010011011011110;  //0.15183416
		w[2][3] = 32'b0000000000000000_0101101101100100;  //0.35700715
		w[2][4] = 32'b0000000000000000_0010100110011101;  //0.16255529
		w[2][5] = 32'b0000000000000000_0000110100011100;  //0.051211603
		w[2][6] = 32'b0000000000000000_0011101101000001;  //0.2314676
		w[2][7] = 32'b0000000000000000_0111110000011000;  //0.4847558
		w[3][0] = 32'b0000000000000000_0010001101100000;  //0.13819431
		w[3][1] = 32'b0000000000000000_0010000101010110;  //0.13023236
		w[3][2] = 32'b0000000000000000_0010000010011010;  //0.12735283
		w[3][3] = 32'b0000000000000000_0000000100111010;  //0.0047966707
		w[3][4] = -32'b0000000000000000_0110010111011111;  //0.3979391
		w[3][5] = 32'b0000000000000000_0001001110100001;  //0.07668239
		w[3][6] = -32'b0000000000000000_0011110110101100;  //0.24091949
		w[3][7] = 32'b0000000000000000_0001110100010111;  //0.11364024
		w[4][0] = 32'b0000000000000000_1010010000011000;  //0.64099807
		w[4][1] = -32'b0000000000000000_0011011101110011;  //0.21660109
		w[4][2] = -32'b0000000000000000_0100110101101111;  //0.30248013
		w[4][3] = 32'b0000000000000000_1011010010110101;  //0.7058874
		w[4][4] = 32'b0000000000000000_1001110101101110;  //0.61496097
		w[4][5] = -32'b0000000000000000_0100111101000010;  //0.3096117
		w[4][6] = 32'b0000000000000000_0111011110011001;  //0.46719027
		w[4][7] = -32'b0000000000000000_0101011001111000;  //0.3377691
		w[5][0] = -32'b0000000000000000_1000010011001110;  //0.51877743
		w[5][1] = 32'b0000000000000000_1011101100100000;  //0.73096454
		w[5][2] = -32'b0000000000000000_0110010110001100;  //0.39667735
		w[5][3] = -32'b0000000000000000_0110111010001111;  //0.43187135
		w[5][4] = 32'b0000000000000000_1000001000010100;  //0.50811917
		w[5][5] = 32'b0000000000000001_0011001001111111;  //1.1972578
		w[5][6] = -32'b0000000000000000_1100111111000000;  //0.8115334
		w[5][7] = -32'b0000000000000000_1101000010010001;  //0.8147229
		w[6][0] = 32'b0000000000000000_0001111110011110;  //0.12351084
		w[6][1] = 32'b0000000000000001_0001011010100111;  //1.0884954
		w[6][2] = 32'b0000000000000000_0111001101010101;  //0.45052522
		w[6][3] = 32'b0000000000000000_1000010100001100;  //0.51972914
		w[6][4] = 32'b0000000000000000_1101111010000110;  //0.86924076
		w[6][5] = 32'b0000000000000001_0000100001010100;  //1.0325365
		w[6][6] = 32'b0000000000000000_0110010101101011;  //0.39617583
		w[6][7] = -32'b0000000000000000_1100100111011101;  //0.7885381
		w[7][0] = 32'b0000000000000000_0110111111010111;  //0.43687996
		w[7][1] = 32'b0000000000000000_1111010100010111;  //0.95739704
		w[7][2] = -32'b0000000000000000_0111000100100111;  //0.44201255
		w[7][3] = -32'b0000000000000001_0111110101011100;  //1.4896935
		w[7][4] = 32'b0000000000000000_0010101010100111;  //0.16661838
		w[7][5] = 32'b0000000000000000_1000111011110100;  //0.55841625
		w[7][6] = 32'b0000000000000000_1000100010100101;  //0.5337692
		w[7][7] = 32'b0000000000000000_0110011000110011;  //0.399223
		//first_layer_biases
		w[8][0] = 32'b0000000000000000_0001101101100101;  //0.10701949
		w[8][1] = -32'b0000000000000000_1010110101111110;  //0.67771715
		w[8][2] = 32'b0000000000000000_0000000000000000;  //0.0
		w[8][3] = 32'b0000000000000000_1010110111000110;  //0.6788025
		w[8][4] = -32'b0000000000000000_1101000011100011;  //0.81597406
		w[8][5] = -32'b0000000000000001_0000001010010001;  //1.0100276
		w[8][6] = 32'b0000000000000000_1110110001100110;  //0.92344064
		w[8][7] = 32'b0000000000000000_1010111011001001;  //0.6827686
		//second_layer_weights
		v[0] = -32'b0000000000000001_0100111101000110;  //-1.3096708
		v[1] = 32'b0000000000000001_0111001101101000;  //1.450813
		v[2] = 32'b0000000000000000_0110101010011000;  //0.4163903
		v[3] = -32'b0000000000000010_0000000111101100;  //-2.0075145
		v[4] = 32'b0000000000000001_1001001001101110;  //1.5719911
		v[5] = 32'b0000000000000001_1000000011001101;  //1.5031285
		v[6] = -32'b0000000000000010_1010000111110110;  //-2.632673
		v[7] = -32'b0000000000000001_0101101110011100;  //-1.3578578
		//second_layer_biases
		v[8] = -32'b0000000000000000_1011000101111100;  //-0.69331163
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
						$display("Entrada %d: %d", i, entradas[i]);
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