/* 
 * Do not change Module name 
*/
module main;

localparam sf = 2.0**-32.0; 

localparam sf16 = 2.0**-16.0; 

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
	
	reg [63:0] k;
	
  initial 
    begin
    
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
		
				
		entradas[0] = 6;entradas[1] = 148;entradas[2] = 72;entradas[3] = 35;entradas[4] = 0;entradas[5] = 34;entradas[6] = 627;entradas[7] = 50;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 85;entradas[2] = 66;entradas[3] = 29;entradas[4] = 0;entradas[5] = 27;entradas[6] = 351;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 183;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 672;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 89;entradas[2] = 66;entradas[3] = 23;entradas[4] = 94;entradas[5] = 28;entradas[6] = 167;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 137;entradas[2] = 40;entradas[3] = 35;entradas[4] = 168;entradas[5] = 43;entradas[6] = 2288;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 116;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 201;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 78;entradas[2] = 50;entradas[3] = 32;entradas[4] = 88;entradas[5] = 31;entradas[6] = 248;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 115;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 134;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 197;entradas[2] = 70;entradas[3] = 45;entradas[4] = 543;entradas[5] = 31;entradas[6] = 158;entradas[7] = 53;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 125;entradas[2] = 96;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 232;entradas[7] = 54;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 110;entradas[2] = 92;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 191;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 168;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 537;entradas[7] = 34;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 139;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 1441;entradas[7] = 57;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 189;entradas[2] = 60;entradas[3] = 23;entradas[4] = 846;entradas[5] = 30;entradas[6] = 398;entradas[7] = 59;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 166;entradas[2] = 72;entradas[3] = 19;entradas[4] = 175;entradas[5] = 26;entradas[6] = 587;entradas[7] = 51;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 100;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 484;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 118;entradas[2] = 84;entradas[3] = 47;entradas[4] = 230;entradas[5] = 46;entradas[6] = 551;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 107;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 254;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 103;entradas[2] = 30;entradas[3] = 38;entradas[4] = 83;entradas[5] = 43;entradas[6] = 183;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 115;entradas[2] = 70;entradas[3] = 30;entradas[4] = 96;entradas[5] = 35;entradas[6] = 529;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 126;entradas[2] = 88;entradas[3] = 41;entradas[4] = 235;entradas[5] = 39;entradas[6] = 704;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 99;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 388;entradas[7] = 50;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 196;entradas[2] = 90;entradas[3] = 0;entradas[4] = 0;entradas[5] = 40;entradas[6] = 451;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 119;entradas[2] = 80;entradas[3] = 35;entradas[4] = 0;entradas[5] = 29;entradas[6] = 263;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 143;entradas[2] = 94;entradas[3] = 33;entradas[4] = 146;entradas[5] = 37;entradas[6] = 254;entradas[7] = 51;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 125;entradas[2] = 70;entradas[3] = 26;entradas[4] = 115;entradas[5] = 31;entradas[6] = 205;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 147;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 257;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 97;entradas[2] = 66;entradas[3] = 15;entradas[4] = 140;entradas[5] = 23;entradas[6] = 487;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 145;entradas[2] = 82;entradas[3] = 19;entradas[4] = 110;entradas[5] = 22;entradas[6] = 245;entradas[7] = 57;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 117;entradas[2] = 92;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 337;entradas[7] = 38;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 109;entradas[2] = 75;entradas[3] = 26;entradas[4] = 0;entradas[5] = 36;entradas[6] = 546;entradas[7] = 60;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 158;entradas[2] = 76;entradas[3] = 36;entradas[4] = 245;entradas[5] = 32;entradas[6] = 851;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 88;entradas[2] = 58;entradas[3] = 11;entradas[4] = 54;entradas[5] = 25;entradas[6] = 267;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 92;entradas[2] = 92;entradas[3] = 0;entradas[4] = 0;entradas[5] = 20;entradas[6] = 188;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 122;entradas[2] = 78;entradas[3] = 31;entradas[4] = 0;entradas[5] = 28;entradas[6] = 512;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 103;entradas[2] = 60;entradas[3] = 33;entradas[4] = 192;entradas[5] = 24;entradas[6] = 966;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 138;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 420;entradas[7] = 35;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 102;entradas[2] = 76;entradas[3] = 37;entradas[4] = 0;entradas[5] = 33;entradas[6] = 665;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 90;entradas[2] = 68;entradas[3] = 42;entradas[4] = 0;entradas[5] = 38;entradas[6] = 503;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 111;entradas[2] = 72;entradas[3] = 47;entradas[4] = 207;entradas[5] = 37;entradas[6] = 1390;entradas[7] = 56;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 180;entradas[2] = 64;entradas[3] = 25;entradas[4] = 70;entradas[5] = 34;entradas[6] = 271;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 133;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 40;entradas[6] = 696;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 106;entradas[2] = 92;entradas[3] = 18;entradas[4] = 0;entradas[5] = 23;entradas[6] = 235;entradas[7] = 48;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 171;entradas[2] = 110;entradas[3] = 24;entradas[4] = 240;entradas[5] = 45;entradas[6] = 721;entradas[7] = 54;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 159;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 294;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 180;entradas[2] = 66;entradas[3] = 39;entradas[4] = 0;entradas[5] = 42;entradas[6] = 1893;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 146;entradas[2] = 56;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 564;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 71;entradas[2] = 70;entradas[3] = 27;entradas[4] = 0;entradas[5] = 28;entradas[6] = 586;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 103;entradas[2] = 66;entradas[3] = 32;entradas[4] = 0;entradas[5] = 39;entradas[6] = 344;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 105;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 305;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 103;entradas[2] = 80;entradas[3] = 11;entradas[4] = 82;entradas[5] = 19;entradas[6] = 491;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 101;entradas[2] = 50;entradas[3] = 15;entradas[4] = 36;entradas[5] = 24;entradas[6] = 526;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 88;entradas[2] = 66;entradas[3] = 21;entradas[4] = 23;entradas[5] = 24;entradas[6] = 342;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 176;entradas[2] = 90;entradas[3] = 34;entradas[4] = 300;entradas[5] = 34;entradas[6] = 467;entradas[7] = 58;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 150;entradas[2] = 66;entradas[3] = 42;entradas[4] = 342;entradas[5] = 35;entradas[6] = 718;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 73;entradas[2] = 50;entradas[3] = 10;entradas[4] = 0;entradas[5] = 23;entradas[6] = 248;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 187;entradas[2] = 68;entradas[3] = 39;entradas[4] = 304;entradas[5] = 38;entradas[6] = 254;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 100;entradas[2] = 88;entradas[3] = 60;entradas[4] = 110;entradas[5] = 47;entradas[6] = 962;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 146;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 41;entradas[6] = 1781;entradas[7] = 44;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 105;entradas[2] = 64;entradas[3] = 41;entradas[4] = 142;entradas[5] = 42;entradas[6] = 173;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 84;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 304;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 133;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 270;entradas[7] = 39;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 44;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 587;entradas[7] = 36;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 141;entradas[2] = 58;entradas[3] = 34;entradas[4] = 128;entradas[5] = 25;entradas[6] = 699;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 114;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 258;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 99;entradas[2] = 74;entradas[3] = 27;entradas[4] = 0;entradas[5] = 29;entradas[6] = 203;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 109;entradas[2] = 88;entradas[3] = 30;entradas[4] = 0;entradas[5] = 33;entradas[6] = 855;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 109;entradas[2] = 92;entradas[3] = 0;entradas[4] = 0;entradas[5] = 43;entradas[6] = 845;entradas[7] = 54;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 95;entradas[2] = 66;entradas[3] = 13;entradas[4] = 38;entradas[5] = 20;entradas[6] = 334;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 146;entradas[2] = 85;entradas[3] = 27;entradas[4] = 100;entradas[5] = 29;entradas[6] = 189;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 100;entradas[2] = 66;entradas[3] = 20;entradas[4] = 90;entradas[5] = 33;entradas[6] = 867;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 139;entradas[2] = 64;entradas[3] = 35;entradas[4] = 140;entradas[5] = 29;entradas[6] = 411;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 126;entradas[2] = 90;entradas[3] = 0;entradas[4] = 0;entradas[5] = 43;entradas[6] = 583;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 129;entradas[2] = 86;entradas[3] = 20;entradas[4] = 270;entradas[5] = 35;entradas[6] = 231;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 79;entradas[2] = 75;entradas[3] = 30;entradas[4] = 0;entradas[5] = 32;entradas[6] = 396;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 0;entradas[2] = 48;entradas[3] = 20;entradas[4] = 0;entradas[5] = 25;entradas[6] = 140;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 62;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 391;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 95;entradas[2] = 72;entradas[3] = 33;entradas[4] = 0;entradas[5] = 38;entradas[6] = 370;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 131;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 43;entradas[6] = 270;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 112;entradas[2] = 66;entradas[3] = 22;entradas[4] = 0;entradas[5] = 25;entradas[6] = 307;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 113;entradas[2] = 44;entradas[3] = 13;entradas[4] = 0;entradas[5] = 22;entradas[6] = 140;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 74;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 102;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 83;entradas[2] = 78;entradas[3] = 26;entradas[4] = 71;entradas[5] = 29;entradas[6] = 767;entradas[7] = 36;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 101;entradas[2] = 65;entradas[3] = 28;entradas[4] = 0;entradas[5] = 25;entradas[6] = 237;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 137;entradas[2] = 108;entradas[3] = 0;entradas[4] = 0;entradas[5] = 49;entradas[6] = 227;entradas[7] = 37;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 110;entradas[2] = 74;entradas[3] = 29;entradas[4] = 125;entradas[5] = 32;entradas[6] = 698;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 106;entradas[2] = 72;entradas[3] = 54;entradas[4] = 0;entradas[5] = 37;entradas[6] = 178;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 100;entradas[2] = 68;entradas[3] = 25;entradas[4] = 71;entradas[5] = 39;entradas[6] = 324;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 15;entradas[1] = 136;entradas[2] = 70;entradas[3] = 32;entradas[4] = 110;entradas[5] = 37;entradas[6] = 153;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 107;entradas[2] = 68;entradas[3] = 19;entradas[4] = 0;entradas[5] = 27;entradas[6] = 165;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 80;entradas[2] = 55;entradas[3] = 0;entradas[4] = 0;entradas[5] = 19;entradas[6] = 258;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 123;entradas[2] = 80;entradas[3] = 15;entradas[4] = 176;entradas[5] = 32;entradas[6] = 443;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 81;entradas[2] = 78;entradas[3] = 40;entradas[4] = 48;entradas[5] = 47;entradas[6] = 261;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 134;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 277;entradas[7] = 60;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 142;entradas[2] = 82;entradas[3] = 18;entradas[4] = 64;entradas[5] = 25;entradas[6] = 761;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 144;entradas[2] = 72;entradas[3] = 27;entradas[4] = 228;entradas[5] = 34;entradas[6] = 255;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 92;entradas[2] = 62;entradas[3] = 28;entradas[4] = 0;entradas[5] = 32;entradas[6] = 130;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 71;entradas[2] = 48;entradas[3] = 18;entradas[4] = 76;entradas[5] = 20;entradas[6] = 323;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 93;entradas[2] = 50;entradas[3] = 30;entradas[4] = 64;entradas[5] = 29;entradas[6] = 356;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 122;entradas[2] = 90;entradas[3] = 51;entradas[4] = 220;entradas[5] = 50;entradas[6] = 325;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 163;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 1222;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 151;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 179;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 125;entradas[2] = 96;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 262;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 81;entradas[2] = 72;entradas[3] = 18;entradas[4] = 40;entradas[5] = 27;entradas[6] = 283;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 85;entradas[2] = 65;entradas[3] = 0;entradas[4] = 0;entradas[5] = 40;entradas[6] = 930;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 126;entradas[2] = 56;entradas[3] = 29;entradas[4] = 152;entradas[5] = 29;entradas[6] = 801;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 96;entradas[2] = 122;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 207;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 144;entradas[2] = 58;entradas[3] = 28;entradas[4] = 140;entradas[5] = 30;entradas[6] = 287;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 83;entradas[2] = 58;entradas[3] = 31;entradas[4] = 18;entradas[5] = 34;entradas[6] = 336;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 95;entradas[2] = 85;entradas[3] = 25;entradas[4] = 36;entradas[5] = 37;entradas[6] = 247;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 171;entradas[2] = 72;entradas[3] = 33;entradas[4] = 135;entradas[5] = 33;entradas[6] = 199;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 155;entradas[2] = 62;entradas[3] = 26;entradas[4] = 495;entradas[5] = 34;entradas[6] = 543;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 89;entradas[2] = 76;entradas[3] = 34;entradas[4] = 37;entradas[5] = 31;entradas[6] = 192;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 76;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 391;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 160;entradas[2] = 54;entradas[3] = 32;entradas[4] = 175;entradas[5] = 31;entradas[6] = 588;entradas[7] = 39;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 146;entradas[2] = 92;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 539;entradas[7] = 61;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 124;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 220;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 78;entradas[2] = 48;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 654;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 97;entradas[2] = 60;entradas[3] = 23;entradas[4] = 0;entradas[5] = 28;entradas[6] = 443;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 99;entradas[2] = 76;entradas[3] = 15;entradas[4] = 51;entradas[5] = 23;entradas[6] = 223;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 162;entradas[2] = 76;entradas[3] = 56;entradas[4] = 100;entradas[5] = 53;entradas[6] = 759;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 111;entradas[2] = 64;entradas[3] = 39;entradas[4] = 0;entradas[5] = 34;entradas[6] = 260;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 107;entradas[2] = 74;entradas[3] = 30;entradas[4] = 100;entradas[5] = 34;entradas[6] = 404;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 132;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 186;entradas[7] = 69;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 113;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 278;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 88;entradas[2] = 30;entradas[3] = 42;entradas[4] = 99;entradas[5] = 55;entradas[6] = 496;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 120;entradas[2] = 70;entradas[3] = 30;entradas[4] = 135;entradas[5] = 43;entradas[6] = 452;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 118;entradas[2] = 58;entradas[3] = 36;entradas[4] = 94;entradas[5] = 33;entradas[6] = 261;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 117;entradas[2] = 88;entradas[3] = 24;entradas[4] = 145;entradas[5] = 35;entradas[6] = 403;entradas[7] = 40;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 105;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 741;entradas[7] = 62;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 173;entradas[2] = 70;entradas[3] = 14;entradas[4] = 168;entradas[5] = 30;entradas[6] = 361;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 122;entradas[2] = 56;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 1114;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 170;entradas[2] = 64;entradas[3] = 37;entradas[4] = 225;entradas[5] = 35;entradas[6] = 356;entradas[7] = 30;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 84;entradas[2] = 74;entradas[3] = 31;entradas[4] = 0;entradas[5] = 38;entradas[6] = 457;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 96;entradas[2] = 68;entradas[3] = 13;entradas[4] = 49;entradas[5] = 21;entradas[6] = 647;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 125;entradas[2] = 60;entradas[3] = 20;entradas[4] = 140;entradas[5] = 34;entradas[6] = 88;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 100;entradas[2] = 70;entradas[3] = 26;entradas[4] = 50;entradas[5] = 31;entradas[6] = 597;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 93;entradas[2] = 60;entradas[3] = 25;entradas[4] = 92;entradas[5] = 29;entradas[6] = 532;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 129;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 703;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 105;entradas[2] = 72;entradas[3] = 29;entradas[4] = 325;entradas[5] = 37;entradas[6] = 159;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 128;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 21;entradas[6] = 268;entradas[7] = 55;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 106;entradas[2] = 82;entradas[3] = 30;entradas[4] = 0;entradas[5] = 40;entradas[6] = 286;entradas[7] = 38;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 108;entradas[2] = 52;entradas[3] = 26;entradas[4] = 63;entradas[5] = 33;entradas[6] = 318;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 108;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 272;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 154;entradas[2] = 62;entradas[3] = 31;entradas[4] = 284;entradas[5] = 33;entradas[6] = 237;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 102;entradas[2] = 75;entradas[3] = 23;entradas[4] = 0;entradas[5] = 0;entradas[6] = 572;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 57;entradas[2] = 80;entradas[3] = 37;entradas[4] = 0;entradas[5] = 33;entradas[6] = 96;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 106;entradas[2] = 64;entradas[3] = 35;entradas[4] = 119;entradas[5] = 31;entradas[6] = 1400;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 147;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 218;entradas[7] = 65;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 90;entradas[2] = 70;entradas[3] = 17;entradas[4] = 0;entradas[5] = 27;entradas[6] = 85;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 136;entradas[2] = 74;entradas[3] = 50;entradas[4] = 204;entradas[5] = 37;entradas[6] = 399;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 114;entradas[2] = 65;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 432;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 156;entradas[2] = 86;entradas[3] = 28;entradas[4] = 155;entradas[5] = 34;entradas[6] = 1189;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 153;entradas[2] = 82;entradas[3] = 42;entradas[4] = 485;entradas[5] = 41;entradas[6] = 687;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 188;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 48;entradas[6] = 137;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 152;entradas[2] = 88;entradas[3] = 44;entradas[4] = 0;entradas[5] = 50;entradas[6] = 337;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 99;entradas[2] = 52;entradas[3] = 15;entradas[4] = 94;entradas[5] = 25;entradas[6] = 637;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 109;entradas[2] = 56;entradas[3] = 21;entradas[4] = 135;entradas[5] = 25;entradas[6] = 833;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 88;entradas[2] = 74;entradas[3] = 19;entradas[4] = 53;entradas[5] = 29;entradas[6] = 229;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 17;entradas[1] = 163;entradas[2] = 72;entradas[3] = 41;entradas[4] = 114;entradas[5] = 41;entradas[6] = 817;entradas[7] = 47;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 151;entradas[2] = 90;entradas[3] = 38;entradas[4] = 0;entradas[5] = 30;entradas[6] = 294;entradas[7] = 36;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 102;entradas[2] = 74;entradas[3] = 40;entradas[4] = 105;entradas[5] = 37;entradas[6] = 204;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 114;entradas[2] = 80;entradas[3] = 34;entradas[4] = 285;entradas[5] = 44;entradas[6] = 167;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 100;entradas[2] = 64;entradas[3] = 23;entradas[4] = 0;entradas[5] = 30;entradas[6] = 368;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 131;entradas[2] = 88;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 743;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 104;entradas[2] = 74;entradas[3] = 18;entradas[4] = 156;entradas[5] = 30;entradas[6] = 722;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 148;entradas[2] = 66;entradas[3] = 25;entradas[4] = 0;entradas[5] = 33;entradas[6] = 256;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 120;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 709;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 110;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 471;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 111;entradas[2] = 90;entradas[3] = 12;entradas[4] = 78;entradas[5] = 28;entradas[6] = 495;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 102;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 180;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 134;entradas[2] = 70;entradas[3] = 23;entradas[4] = 130;entradas[5] = 35;entradas[6] = 542;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 87;entradas[2] = 0;entradas[3] = 23;entradas[4] = 0;entradas[5] = 29;entradas[6] = 773;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 79;entradas[2] = 60;entradas[3] = 42;entradas[4] = 48;entradas[5] = 44;entradas[6] = 678;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 75;entradas[2] = 64;entradas[3] = 24;entradas[4] = 55;entradas[5] = 30;entradas[6] = 370;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 179;entradas[2] = 72;entradas[3] = 42;entradas[4] = 130;entradas[5] = 33;entradas[6] = 719;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 85;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 382;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 129;entradas[2] = 110;entradas[3] = 46;entradas[4] = 130;entradas[5] = 67;entradas[6] = 319;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 143;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 45;entradas[6] = 190;entradas[7] = 47;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 130;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 956;entradas[7] = 37;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 87;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 84;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 119;entradas[2] = 64;entradas[3] = 18;entradas[4] = 92;entradas[5] = 35;entradas[6] = 725;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 0;entradas[2] = 74;entradas[3] = 20;entradas[4] = 23;entradas[5] = 28;entradas[6] = 299;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 73;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 268;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 141;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 244;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 194;entradas[2] = 68;entradas[3] = 28;entradas[4] = 0;entradas[5] = 36;entradas[6] = 745;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 181;entradas[2] = 68;entradas[3] = 36;entradas[4] = 495;entradas[5] = 30;entradas[6] = 615;entradas[7] = 60;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 128;entradas[2] = 98;entradas[3] = 41;entradas[4] = 58;entradas[5] = 32;entradas[6] = 1321;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 109;entradas[2] = 76;entradas[3] = 39;entradas[4] = 114;entradas[5] = 28;entradas[6] = 640;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 139;entradas[2] = 80;entradas[3] = 35;entradas[4] = 160;entradas[5] = 32;entradas[6] = 361;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 111;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 142;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 123;entradas[2] = 70;entradas[3] = 44;entradas[4] = 94;entradas[5] = 33;entradas[6] = 374;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 159;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 383;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 135;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 52;entradas[6] = 578;entradas[7] = 40;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 85;entradas[2] = 55;entradas[3] = 20;entradas[4] = 0;entradas[5] = 24;entradas[6] = 136;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 158;entradas[2] = 84;entradas[3] = 41;entradas[4] = 210;entradas[5] = 39;entradas[6] = 395;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 105;entradas[2] = 58;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 187;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 107;entradas[2] = 62;entradas[3] = 13;entradas[4] = 48;entradas[5] = 23;entradas[6] = 678;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 109;entradas[2] = 64;entradas[3] = 44;entradas[4] = 99;entradas[5] = 35;entradas[6] = 905;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 148;entradas[2] = 60;entradas[3] = 27;entradas[4] = 318;entradas[5] = 31;entradas[6] = 150;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 113;entradas[2] = 80;entradas[3] = 16;entradas[4] = 0;entradas[5] = 31;entradas[6] = 874;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 138;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 40;entradas[6] = 236;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 108;entradas[2] = 68;entradas[3] = 20;entradas[4] = 0;entradas[5] = 27;entradas[6] = 787;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 99;entradas[2] = 70;entradas[3] = 16;entradas[4] = 44;entradas[5] = 20;entradas[6] = 235;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 103;entradas[2] = 72;entradas[3] = 32;entradas[4] = 190;entradas[5] = 38;entradas[6] = 324;entradas[7] = 55;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 111;entradas[2] = 72;entradas[3] = 28;entradas[4] = 0;entradas[5] = 24;entradas[6] = 407;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 196;entradas[2] = 76;entradas[3] = 29;entradas[4] = 280;entradas[5] = 38;entradas[6] = 605;entradas[7] = 57;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 162;entradas[2] = 104;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 151;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 96;entradas[2] = 64;entradas[3] = 27;entradas[4] = 87;entradas[5] = 33;entradas[6] = 289;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 184;entradas[2] = 84;entradas[3] = 33;entradas[4] = 0;entradas[5] = 36;entradas[6] = 355;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 81;entradas[2] = 60;entradas[3] = 22;entradas[4] = 0;entradas[5] = 28;entradas[6] = 290;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 147;entradas[2] = 85;entradas[3] = 54;entradas[4] = 0;entradas[5] = 43;entradas[6] = 375;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 179;entradas[2] = 95;entradas[3] = 31;entradas[4] = 0;entradas[5] = 34;entradas[6] = 164;entradas[7] = 60;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 140;entradas[2] = 65;entradas[3] = 26;entradas[4] = 130;entradas[5] = 43;entradas[6] = 431;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 112;entradas[2] = 82;entradas[3] = 32;entradas[4] = 175;entradas[5] = 34;entradas[6] = 260;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 151;entradas[2] = 70;entradas[3] = 40;entradas[4] = 271;entradas[5] = 42;entradas[6] = 742;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 109;entradas[2] = 62;entradas[3] = 41;entradas[4] = 129;entradas[5] = 36;entradas[6] = 514;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 125;entradas[2] = 68;entradas[3] = 30;entradas[4] = 120;entradas[5] = 30;entradas[6] = 464;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 85;entradas[2] = 74;entradas[3] = 22;entradas[4] = 0;entradas[5] = 29;entradas[6] = 1224;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 112;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 261;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 177;entradas[2] = 60;entradas[3] = 29;entradas[4] = 478;entradas[5] = 35;entradas[6] = 1072;entradas[7] = 21;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 158;entradas[2] = 90;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 805;entradas[7] = 66;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 119;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 209;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 142;entradas[2] = 60;entradas[3] = 33;entradas[4] = 190;entradas[5] = 29;entradas[6] = 687;entradas[7] = 61;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 100;entradas[2] = 66;entradas[3] = 15;entradas[4] = 56;entradas[5] = 24;entradas[6] = 666;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 87;entradas[2] = 78;entradas[3] = 27;entradas[4] = 32;entradas[5] = 35;entradas[6] = 101;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 101;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 36;entradas[6] = 198;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 162;entradas[2] = 52;entradas[3] = 38;entradas[4] = 0;entradas[5] = 37;entradas[6] = 652;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 197;entradas[2] = 70;entradas[3] = 39;entradas[4] = 744;entradas[5] = 37;entradas[6] = 2329;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 117;entradas[2] = 80;entradas[3] = 31;entradas[4] = 53;entradas[5] = 45;entradas[6] = 89;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 142;entradas[2] = 86;entradas[3] = 0;entradas[4] = 0;entradas[5] = 44;entradas[6] = 645;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 134;entradas[2] = 80;entradas[3] = 37;entradas[4] = 370;entradas[5] = 46;entradas[6] = 238;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 79;entradas[2] = 80;entradas[3] = 25;entradas[4] = 37;entradas[5] = 25;entradas[6] = 583;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 122;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 394;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 74;entradas[2] = 68;entradas[3] = 28;entradas[4] = 45;entradas[5] = 30;entradas[6] = 293;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 171;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 44;entradas[6] = 479;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 181;entradas[2] = 84;entradas[3] = 21;entradas[4] = 192;entradas[5] = 36;entradas[6] = 586;entradas[7] = 51;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 179;entradas[2] = 90;entradas[3] = 27;entradas[4] = 0;entradas[5] = 44;entradas[6] = 686;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 164;entradas[2] = 84;entradas[3] = 21;entradas[4] = 0;entradas[5] = 31;entradas[6] = 831;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 104;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 18;entradas[6] = 582;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 91;entradas[2] = 64;entradas[3] = 24;entradas[4] = 0;entradas[5] = 29;entradas[6] = 192;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 91;entradas[2] = 70;entradas[3] = 32;entradas[4] = 88;entradas[5] = 33;entradas[6] = 446;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 139;entradas[2] = 54;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 402;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 119;entradas[2] = 50;entradas[3] = 22;entradas[4] = 176;entradas[5] = 27;entradas[6] = 1318;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 146;entradas[2] = 76;entradas[3] = 35;entradas[4] = 194;entradas[5] = 38;entradas[6] = 329;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 184;entradas[2] = 85;entradas[3] = 15;entradas[4] = 0;entradas[5] = 30;entradas[6] = 1213;entradas[7] = 49;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 122;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 258;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 165;entradas[2] = 90;entradas[3] = 33;entradas[4] = 680;entradas[5] = 52;entradas[6] = 427;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 124;entradas[2] = 70;entradas[3] = 33;entradas[4] = 402;entradas[5] = 35;entradas[6] = 282;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 111;entradas[2] = 86;entradas[3] = 19;entradas[4] = 0;entradas[5] = 30;entradas[6] = 143;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 106;entradas[2] = 52;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 380;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 129;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 284;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 90;entradas[2] = 80;entradas[3] = 14;entradas[4] = 55;entradas[5] = 24;entradas[6] = 249;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 86;entradas[2] = 68;entradas[3] = 32;entradas[4] = 0;entradas[5] = 36;entradas[6] = 238;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 92;entradas[2] = 62;entradas[3] = 7;entradas[4] = 258;entradas[5] = 28;entradas[6] = 926;entradas[7] = 44;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 113;entradas[2] = 64;entradas[3] = 35;entradas[4] = 0;entradas[5] = 34;entradas[6] = 543;entradas[7] = 21;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 111;entradas[2] = 56;entradas[3] = 39;entradas[4] = 0;entradas[5] = 30;entradas[6] = 557;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 114;entradas[2] = 68;entradas[3] = 22;entradas[4] = 0;entradas[5] = 29;entradas[6] = 92;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 193;entradas[2] = 50;entradas[3] = 16;entradas[4] = 375;entradas[5] = 26;entradas[6] = 655;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 155;entradas[2] = 76;entradas[3] = 28;entradas[4] = 150;entradas[5] = 33;entradas[6] = 1353;entradas[7] = 51;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 191;entradas[2] = 68;entradas[3] = 15;entradas[4] = 130;entradas[5] = 31;entradas[6] = 299;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 141;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 761;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 95;entradas[2] = 70;entradas[3] = 32;entradas[4] = 0;entradas[5] = 32;entradas[6] = 612;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 142;entradas[2] = 80;entradas[3] = 15;entradas[4] = 0;entradas[5] = 32;entradas[6] = 200;entradas[7] = 63;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 123;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 226;entradas[7] = 35;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 96;entradas[2] = 74;entradas[3] = 18;entradas[4] = 67;entradas[5] = 34;entradas[6] = 997;entradas[7] = 43;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 138;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 36;entradas[6] = 933;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 128;entradas[2] = 64;entradas[3] = 42;entradas[4] = 0;entradas[5] = 40;entradas[6] = 1101;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 102;entradas[2] = 52;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 78;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 146;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 240;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 101;entradas[2] = 86;entradas[3] = 37;entradas[4] = 0;entradas[5] = 46;entradas[6] = 1136;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 108;entradas[2] = 62;entradas[3] = 32;entradas[4] = 56;entradas[5] = 25;entradas[6] = 128;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 122;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 254;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 71;entradas[2] = 78;entradas[3] = 50;entradas[4] = 45;entradas[5] = 33;entradas[6] = 422;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 106;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 251;entradas[7] = 52;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 100;entradas[2] = 70;entradas[3] = 52;entradas[4] = 57;entradas[5] = 41;entradas[6] = 677;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 106;entradas[2] = 60;entradas[3] = 24;entradas[4] = 0;entradas[5] = 27;entradas[6] = 296;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 104;entradas[2] = 64;entradas[3] = 23;entradas[4] = 116;entradas[5] = 28;entradas[6] = 454;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 114;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 744;entradas[7] = 57;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 108;entradas[2] = 62;entradas[3] = 10;entradas[4] = 278;entradas[5] = 25;entradas[6] = 881;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 146;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 334;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 129;entradas[2] = 76;entradas[3] = 28;entradas[4] = 122;entradas[5] = 36;entradas[6] = 280;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 133;entradas[2] = 88;entradas[3] = 15;entradas[4] = 155;entradas[5] = 32;entradas[6] = 262;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 161;entradas[2] = 86;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 165;entradas[7] = 47;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 108;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 259;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 136;entradas[2] = 74;entradas[3] = 26;entradas[4] = 135;entradas[5] = 26;entradas[6] = 647;entradas[7] = 51;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 155;entradas[2] = 84;entradas[3] = 44;entradas[4] = 545;entradas[5] = 39;entradas[6] = 619;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 119;entradas[2] = 86;entradas[3] = 39;entradas[4] = 220;entradas[5] = 46;entradas[6] = 808;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 96;entradas[2] = 56;entradas[3] = 17;entradas[4] = 49;entradas[5] = 21;entradas[6] = 340;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 108;entradas[2] = 72;entradas[3] = 43;entradas[4] = 75;entradas[5] = 36;entradas[6] = 263;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 78;entradas[2] = 88;entradas[3] = 29;entradas[4] = 40;entradas[5] = 37;entradas[6] = 434;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 107;entradas[2] = 62;entradas[3] = 30;entradas[4] = 74;entradas[5] = 37;entradas[6] = 757;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 128;entradas[2] = 78;entradas[3] = 37;entradas[4] = 182;entradas[5] = 43;entradas[6] = 1224;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 128;entradas[2] = 48;entradas[3] = 45;entradas[4] = 194;entradas[5] = 41;entradas[6] = 613;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 161;entradas[2] = 50;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 254;entradas[7] = 65;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 151;entradas[2] = 62;entradas[3] = 31;entradas[4] = 120;entradas[5] = 36;entradas[6] = 692;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 146;entradas[2] = 70;entradas[3] = 38;entradas[4] = 360;entradas[5] = 28;entradas[6] = 337;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 126;entradas[2] = 84;entradas[3] = 29;entradas[4] = 215;entradas[5] = 31;entradas[6] = 520;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 14;entradas[1] = 100;entradas[2] = 78;entradas[3] = 25;entradas[4] = 184;entradas[5] = 37;entradas[6] = 412;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 112;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 840;entradas[7] = 58;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 167;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 839;entradas[7] = 30;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 144;entradas[2] = 58;entradas[3] = 33;entradas[4] = 135;entradas[5] = 32;entradas[6] = 422;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 77;entradas[2] = 82;entradas[3] = 41;entradas[4] = 42;entradas[5] = 36;entradas[6] = 156;entradas[7] = 35;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 115;entradas[2] = 98;entradas[3] = 0;entradas[4] = 0;entradas[5] = 53;entradas[6] = 209;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 150;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 21;entradas[6] = 207;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 120;entradas[2] = 76;entradas[3] = 37;entradas[4] = 105;entradas[5] = 40;entradas[6] = 215;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 161;entradas[2] = 68;entradas[3] = 23;entradas[4] = 132;entradas[5] = 26;entradas[6] = 326;entradas[7] = 47;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 137;entradas[2] = 68;entradas[3] = 14;entradas[4] = 148;entradas[5] = 25;entradas[6] = 143;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 128;entradas[2] = 68;entradas[3] = 19;entradas[4] = 180;entradas[5] = 31;entradas[6] = 1391;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 124;entradas[2] = 68;entradas[3] = 28;entradas[4] = 205;entradas[5] = 33;entradas[6] = 875;entradas[7] = 30;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 80;entradas[2] = 66;entradas[3] = 30;entradas[4] = 0;entradas[5] = 26;entradas[6] = 313;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 106;entradas[2] = 70;entradas[3] = 37;entradas[4] = 148;entradas[5] = 39;entradas[6] = 605;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 155;entradas[2] = 74;entradas[3] = 17;entradas[4] = 96;entradas[5] = 27;entradas[6] = 433;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 113;entradas[2] = 50;entradas[3] = 10;entradas[4] = 85;entradas[5] = 30;entradas[6] = 626;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 109;entradas[2] = 80;entradas[3] = 31;entradas[4] = 0;entradas[5] = 36;entradas[6] = 1127;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 112;entradas[2] = 68;entradas[3] = 22;entradas[4] = 94;entradas[5] = 34;entradas[6] = 315;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 99;entradas[2] = 80;entradas[3] = 11;entradas[4] = 64;entradas[5] = 19;entradas[6] = 284;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 182;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 345;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 115;entradas[2] = 66;entradas[3] = 39;entradas[4] = 140;entradas[5] = 38;entradas[6] = 150;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 194;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 129;entradas[7] = 59;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 129;entradas[2] = 60;entradas[3] = 12;entradas[4] = 231;entradas[5] = 28;entradas[6] = 527;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 112;entradas[2] = 74;entradas[3] = 30;entradas[4] = 0;entradas[5] = 32;entradas[6] = 197;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 124;entradas[2] = 70;entradas[3] = 20;entradas[4] = 0;entradas[5] = 27;entradas[6] = 254;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 152;entradas[2] = 90;entradas[3] = 33;entradas[4] = 29;entradas[5] = 27;entradas[6] = 731;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 112;entradas[2] = 75;entradas[3] = 32;entradas[4] = 0;entradas[5] = 36;entradas[6] = 148;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 157;entradas[2] = 72;entradas[3] = 21;entradas[4] = 168;entradas[5] = 26;entradas[6] = 123;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 122;entradas[2] = 64;entradas[3] = 32;entradas[4] = 156;entradas[5] = 35;entradas[6] = 692;entradas[7] = 30;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 179;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 200;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 102;entradas[2] = 86;entradas[3] = 36;entradas[4] = 120;entradas[5] = 46;entradas[6] = 127;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 105;entradas[2] = 70;entradas[3] = 32;entradas[4] = 68;entradas[5] = 31;entradas[6] = 122;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 118;entradas[2] = 72;entradas[3] = 19;entradas[4] = 0;entradas[5] = 23;entradas[6] = 1476;entradas[7] = 46;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 87;entradas[2] = 58;entradas[3] = 16;entradas[4] = 52;entradas[5] = 33;entradas[6] = 166;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 180;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 43;entradas[6] = 282;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 106;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 137;entradas[7] = 44;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 95;entradas[2] = 60;entradas[3] = 18;entradas[4] = 58;entradas[5] = 24;entradas[6] = 260;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 165;entradas[2] = 76;entradas[3] = 43;entradas[4] = 255;entradas[5] = 48;entradas[6] = 259;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 117;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 932;entradas[7] = 44;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 115;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 343;entradas[7] = 44;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 152;entradas[2] = 78;entradas[3] = 34;entradas[4] = 171;entradas[5] = 34;entradas[6] = 893;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 178;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 40;entradas[6] = 331;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 130;entradas[2] = 70;entradas[3] = 13;entradas[4] = 105;entradas[5] = 26;entradas[6] = 472;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 95;entradas[2] = 74;entradas[3] = 21;entradas[4] = 73;entradas[5] = 26;entradas[6] = 673;entradas[7] = 36;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 0;entradas[2] = 68;entradas[3] = 35;entradas[4] = 0;entradas[5] = 32;entradas[6] = 389;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 122;entradas[2] = 86;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 290;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 95;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 37;entradas[6] = 485;entradas[7] = 57;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 126;entradas[2] = 88;entradas[3] = 36;entradas[4] = 108;entradas[5] = 39;entradas[6] = 349;entradas[7] = 49;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 139;entradas[2] = 46;entradas[3] = 19;entradas[4] = 83;entradas[5] = 29;entradas[6] = 654;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 116;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 187;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 99;entradas[2] = 62;entradas[3] = 19;entradas[4] = 74;entradas[5] = 22;entradas[6] = 279;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 0;entradas[2] = 80;entradas[3] = 32;entradas[4] = 0;entradas[5] = 41;entradas[6] = 346;entradas[7] = 37;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 92;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 42;entradas[6] = 237;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 137;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 252;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 61;entradas[2] = 82;entradas[3] = 28;entradas[4] = 0;entradas[5] = 34;entradas[6] = 243;entradas[7] = 46;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 90;entradas[2] = 62;entradas[3] = 12;entradas[4] = 43;entradas[5] = 27;entradas[6] = 580;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 90;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 43;entradas[6] = 559;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 165;entradas[2] = 88;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 302;entradas[7] = 49;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 125;entradas[2] = 50;entradas[3] = 40;entradas[4] = 167;entradas[5] = 33;entradas[6] = 962;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 129;entradas[2] = 0;entradas[3] = 30;entradas[4] = 0;entradas[5] = 40;entradas[6] = 569;entradas[7] = 44;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 88;entradas[2] = 74;entradas[3] = 40;entradas[4] = 54;entradas[5] = 35;entradas[6] = 378;entradas[7] = 48;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 196;entradas[2] = 76;entradas[3] = 36;entradas[4] = 249;entradas[5] = 37;entradas[6] = 875;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 189;entradas[2] = 64;entradas[3] = 33;entradas[4] = 325;entradas[5] = 31;entradas[6] = 583;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 158;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 207;entradas[7] = 63;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 103;entradas[2] = 108;entradas[3] = 37;entradas[4] = 0;entradas[5] = 39;entradas[6] = 305;entradas[7] = 65;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 146;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 520;entradas[7] = 67;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 147;entradas[2] = 74;entradas[3] = 25;entradas[4] = 293;entradas[5] = 35;entradas[6] = 385;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 99;entradas[2] = 54;entradas[3] = 28;entradas[4] = 83;entradas[5] = 34;entradas[6] = 499;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 124;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 368;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 101;entradas[2] = 64;entradas[3] = 17;entradas[4] = 0;entradas[5] = 21;entradas[6] = 252;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 81;entradas[2] = 86;entradas[3] = 16;entradas[4] = 66;entradas[5] = 28;entradas[6] = 306;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 133;entradas[2] = 102;entradas[3] = 28;entradas[4] = 140;entradas[5] = 33;entradas[6] = 234;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 173;entradas[2] = 82;entradas[3] = 48;entradas[4] = 465;entradas[5] = 38;entradas[6] = 2137;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 118;entradas[2] = 64;entradas[3] = 23;entradas[4] = 89;entradas[5] = 0;entradas[6] = 1731;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 84;entradas[2] = 64;entradas[3] = 22;entradas[4] = 66;entradas[5] = 36;entradas[6] = 545;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 105;entradas[2] = 58;entradas[3] = 40;entradas[4] = 94;entradas[5] = 35;entradas[6] = 225;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 122;entradas[2] = 52;entradas[3] = 43;entradas[4] = 158;entradas[5] = 36;entradas[6] = 816;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 140;entradas[2] = 82;entradas[3] = 43;entradas[4] = 325;entradas[5] = 39;entradas[6] = 528;entradas[7] = 58;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 98;entradas[2] = 82;entradas[3] = 15;entradas[4] = 84;entradas[5] = 25;entradas[6] = 299;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 87;entradas[2] = 60;entradas[3] = 37;entradas[4] = 75;entradas[5] = 37;entradas[6] = 509;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 156;entradas[2] = 75;entradas[3] = 0;entradas[4] = 0;entradas[5] = 48;entradas[6] = 238;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 93;entradas[2] = 100;entradas[3] = 39;entradas[4] = 72;entradas[5] = 43;entradas[6] = 1021;entradas[7] = 35;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 107;entradas[2] = 72;entradas[3] = 30;entradas[4] = 82;entradas[5] = 31;entradas[6] = 821;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 105;entradas[2] = 68;entradas[3] = 22;entradas[4] = 0;entradas[5] = 20;entradas[6] = 236;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 109;entradas[2] = 60;entradas[3] = 8;entradas[4] = 182;entradas[5] = 25;entradas[6] = 947;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 90;entradas[2] = 62;entradas[3] = 18;entradas[4] = 59;entradas[5] = 25;entradas[6] = 1268;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 125;entradas[2] = 70;entradas[3] = 24;entradas[4] = 110;entradas[5] = 24;entradas[6] = 221;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 119;entradas[2] = 54;entradas[3] = 13;entradas[4] = 50;entradas[5] = 22;entradas[6] = 205;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 116;entradas[2] = 74;entradas[3] = 29;entradas[4] = 0;entradas[5] = 32;entradas[6] = 660;entradas[7] = 35;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 105;entradas[2] = 100;entradas[3] = 36;entradas[4] = 0;entradas[5] = 43;entradas[6] = 239;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 144;entradas[2] = 82;entradas[3] = 26;entradas[4] = 285;entradas[5] = 32;entradas[6] = 452;entradas[7] = 58;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 100;entradas[2] = 68;entradas[3] = 23;entradas[4] = 81;entradas[5] = 32;entradas[6] = 949;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 100;entradas[2] = 66;entradas[3] = 29;entradas[4] = 196;entradas[5] = 32;entradas[6] = 444;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 166;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 46;entradas[6] = 340;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 131;entradas[2] = 64;entradas[3] = 14;entradas[4] = 415;entradas[5] = 24;entradas[6] = 389;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 116;entradas[2] = 72;entradas[3] = 12;entradas[4] = 87;entradas[5] = 22;entradas[6] = 463;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 158;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 803;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 127;entradas[2] = 58;entradas[3] = 24;entradas[4] = 275;entradas[5] = 28;entradas[6] = 1600;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 96;entradas[2] = 56;entradas[3] = 34;entradas[4] = 115;entradas[5] = 25;entradas[6] = 944;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 131;entradas[2] = 66;entradas[3] = 40;entradas[4] = 0;entradas[5] = 34;entradas[6] = 196;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 82;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 21;entradas[6] = 389;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 193;entradas[2] = 70;entradas[3] = 31;entradas[4] = 0;entradas[5] = 35;entradas[6] = 241;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 95;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 161;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 137;entradas[2] = 61;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 151;entradas[7] = 55;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 136;entradas[2] = 84;entradas[3] = 41;entradas[4] = 88;entradas[5] = 35;entradas[6] = 286;entradas[7] = 35;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 72;entradas[2] = 78;entradas[3] = 25;entradas[4] = 0;entradas[5] = 32;entradas[6] = 280;entradas[7] = 38;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 168;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 135;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 123;entradas[2] = 48;entradas[3] = 32;entradas[4] = 165;entradas[5] = 42;entradas[6] = 520;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 115;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 29;entradas[6] = 376;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 101;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 336;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 197;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 1191;entradas[7] = 39;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 172;entradas[2] = 68;entradas[3] = 49;entradas[4] = 579;entradas[5] = 42;entradas[6] = 702;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 102;entradas[2] = 90;entradas[3] = 39;entradas[4] = 0;entradas[5] = 36;entradas[6] = 674;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 112;entradas[2] = 72;entradas[3] = 30;entradas[4] = 176;entradas[5] = 34;entradas[6] = 528;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 143;entradas[2] = 84;entradas[3] = 23;entradas[4] = 310;entradas[5] = 42;entradas[6] = 1076;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 143;entradas[2] = 74;entradas[3] = 22;entradas[4] = 61;entradas[5] = 26;entradas[6] = 256;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 138;entradas[2] = 60;entradas[3] = 35;entradas[4] = 167;entradas[5] = 35;entradas[6] = 534;entradas[7] = 21;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 173;entradas[2] = 84;entradas[3] = 33;entradas[4] = 474;entradas[5] = 36;entradas[6] = 258;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 97;entradas[2] = 68;entradas[3] = 21;entradas[4] = 0;entradas[5] = 27;entradas[6] = 1095;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 144;entradas[2] = 82;entradas[3] = 32;entradas[4] = 0;entradas[5] = 39;entradas[6] = 554;entradas[7] = 37;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 83;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 18;entradas[6] = 624;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 129;entradas[2] = 64;entradas[3] = 29;entradas[4] = 115;entradas[5] = 26;entradas[6] = 219;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 119;entradas[2] = 88;entradas[3] = 41;entradas[4] = 170;entradas[5] = 45;entradas[6] = 507;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 94;entradas[2] = 68;entradas[3] = 18;entradas[4] = 76;entradas[5] = 26;entradas[6] = 561;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 102;entradas[2] = 64;entradas[3] = 46;entradas[4] = 78;entradas[5] = 41;entradas[6] = 496;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 115;entradas[2] = 64;entradas[3] = 22;entradas[4] = 0;entradas[5] = 31;entradas[6] = 421;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 151;entradas[2] = 78;entradas[3] = 32;entradas[4] = 210;entradas[5] = 43;entradas[6] = 516;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 184;entradas[2] = 78;entradas[3] = 39;entradas[4] = 277;entradas[5] = 37;entradas[6] = 264;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 94;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 256;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 181;entradas[2] = 64;entradas[3] = 30;entradas[4] = 180;entradas[5] = 34;entradas[6] = 328;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 135;entradas[2] = 94;entradas[3] = 46;entradas[4] = 145;entradas[5] = 41;entradas[6] = 284;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 95;entradas[2] = 82;entradas[3] = 25;entradas[4] = 180;entradas[5] = 35;entradas[6] = 233;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 99;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 108;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 89;entradas[2] = 74;entradas[3] = 16;entradas[4] = 85;entradas[5] = 30;entradas[6] = 551;entradas[7] = 38;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 80;entradas[2] = 74;entradas[3] = 11;entradas[4] = 60;entradas[5] = 30;entradas[6] = 527;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 139;entradas[2] = 75;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 167;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 90;entradas[2] = 68;entradas[3] = 8;entradas[4] = 0;entradas[5] = 25;entradas[6] = 1138;entradas[7] = 36;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 141;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 42;entradas[6] = 205;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 140;entradas[2] = 85;entradas[3] = 33;entradas[4] = 0;entradas[5] = 37;entradas[6] = 244;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 147;entradas[2] = 75;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 434;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 97;entradas[2] = 70;entradas[3] = 15;entradas[4] = 0;entradas[5] = 18;entradas[6] = 147;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 107;entradas[2] = 88;entradas[3] = 0;entradas[4] = 0;entradas[5] = 37;entradas[6] = 727;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 189;entradas[2] = 104;entradas[3] = 25;entradas[4] = 0;entradas[5] = 34;entradas[6] = 435;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 83;entradas[2] = 66;entradas[3] = 23;entradas[4] = 50;entradas[5] = 32;entradas[6] = 497;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 117;entradas[2] = 64;entradas[3] = 27;entradas[4] = 120;entradas[5] = 33;entradas[6] = 230;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 108;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 955;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 117;entradas[2] = 62;entradas[3] = 12;entradas[4] = 0;entradas[5] = 30;entradas[6] = 380;entradas[7] = 30;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 180;entradas[2] = 78;entradas[3] = 63;entradas[4] = 14;entradas[5] = 59;entradas[6] = 2420;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 100;entradas[2] = 72;entradas[3] = 12;entradas[4] = 70;entradas[5] = 25;entradas[6] = 658;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 95;entradas[2] = 80;entradas[3] = 45;entradas[4] = 92;entradas[5] = 37;entradas[6] = 330;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 104;entradas[2] = 64;entradas[3] = 37;entradas[4] = 64;entradas[5] = 34;entradas[6] = 510;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 120;entradas[2] = 74;entradas[3] = 18;entradas[4] = 63;entradas[5] = 31;entradas[6] = 285;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 82;entradas[2] = 64;entradas[3] = 13;entradas[4] = 95;entradas[5] = 21;entradas[6] = 415;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 134;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 29;entradas[6] = 542;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 91;entradas[2] = 68;entradas[3] = 32;entradas[4] = 210;entradas[5] = 40;entradas[6] = 381;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 119;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 20;entradas[6] = 832;entradas[7] = 72;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 100;entradas[2] = 54;entradas[3] = 28;entradas[4] = 105;entradas[5] = 38;entradas[6] = 498;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 14;entradas[1] = 175;entradas[2] = 62;entradas[3] = 30;entradas[4] = 0;entradas[5] = 34;entradas[6] = 212;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 135;entradas[2] = 54;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 687;entradas[7] = 62;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 86;entradas[2] = 68;entradas[3] = 28;entradas[4] = 71;entradas[5] = 30;entradas[6] = 364;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 148;entradas[2] = 84;entradas[3] = 48;entradas[4] = 237;entradas[5] = 38;entradas[6] = 1001;entradas[7] = 51;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 134;entradas[2] = 74;entradas[3] = 33;entradas[4] = 60;entradas[5] = 26;entradas[6] = 460;entradas[7] = 81;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 120;entradas[2] = 72;entradas[3] = 22;entradas[4] = 56;entradas[5] = 21;entradas[6] = 733;entradas[7] = 48;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 71;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 416;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 74;entradas[2] = 70;entradas[3] = 40;entradas[4] = 49;entradas[5] = 35;entradas[6] = 705;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 88;entradas[2] = 78;entradas[3] = 30;entradas[4] = 0;entradas[5] = 28;entradas[6] = 258;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 115;entradas[2] = 98;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 1022;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 124;entradas[2] = 56;entradas[3] = 13;entradas[4] = 105;entradas[5] = 22;entradas[6] = 452;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 74;entradas[2] = 52;entradas[3] = 10;entradas[4] = 36;entradas[5] = 28;entradas[6] = 269;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 97;entradas[2] = 64;entradas[3] = 36;entradas[4] = 100;entradas[5] = 37;entradas[6] = 600;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 120;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 183;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 154;entradas[2] = 78;entradas[3] = 41;entradas[4] = 140;entradas[5] = 46;entradas[6] = 571;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 144;entradas[2] = 82;entradas[3] = 40;entradas[4] = 0;entradas[5] = 41;entradas[6] = 607;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 137;entradas[2] = 70;entradas[3] = 38;entradas[4] = 0;entradas[5] = 33;entradas[6] = 170;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 119;entradas[2] = 66;entradas[3] = 27;entradas[4] = 0;entradas[5] = 39;entradas[6] = 259;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 136;entradas[2] = 90;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 210;entradas[7] = 50;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 114;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 29;entradas[6] = 126;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 137;entradas[2] = 84;entradas[3] = 27;entradas[4] = 0;entradas[5] = 27;entradas[6] = 231;entradas[7] = 59;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 105;entradas[2] = 80;entradas[3] = 45;entradas[4] = 191;entradas[5] = 34;entradas[6] = 711;entradas[7] = 29;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 114;entradas[2] = 76;entradas[3] = 17;entradas[4] = 110;entradas[5] = 24;entradas[6] = 466;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 126;entradas[2] = 74;entradas[3] = 38;entradas[4] = 75;entradas[5] = 26;entradas[6] = 162;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 132;entradas[2] = 86;entradas[3] = 31;entradas[4] = 0;entradas[5] = 28;entradas[6] = 419;entradas[7] = 63;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 158;entradas[2] = 70;entradas[3] = 30;entradas[4] = 328;entradas[5] = 36;entradas[6] = 344;entradas[7] = 35;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 123;entradas[2] = 88;entradas[3] = 37;entradas[4] = 0;entradas[5] = 35;entradas[6] = 197;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 85;entradas[2] = 58;entradas[3] = 22;entradas[4] = 49;entradas[5] = 28;entradas[6] = 306;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 84;entradas[2] = 82;entradas[3] = 31;entradas[4] = 125;entradas[5] = 38;entradas[6] = 233;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 145;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 44;entradas[6] = 630;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 135;entradas[2] = 68;entradas[3] = 42;entradas[4] = 250;entradas[5] = 42;entradas[6] = 365;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 139;entradas[2] = 62;entradas[3] = 41;entradas[4] = 480;entradas[5] = 41;entradas[6] = 536;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 173;entradas[2] = 78;entradas[3] = 32;entradas[4] = 265;entradas[5] = 47;entradas[6] = 1159;entradas[7] = 58;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 99;entradas[2] = 72;entradas[3] = 17;entradas[4] = 0;entradas[5] = 26;entradas[6] = 294;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 194;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 551;entradas[7] = 67;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 83;entradas[2] = 65;entradas[3] = 28;entradas[4] = 66;entradas[5] = 37;entradas[6] = 629;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 89;entradas[2] = 90;entradas[3] = 30;entradas[4] = 0;entradas[5] = 34;entradas[6] = 292;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 99;entradas[2] = 68;entradas[3] = 38;entradas[4] = 0;entradas[5] = 33;entradas[6] = 145;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 125;entradas[2] = 70;entradas[3] = 18;entradas[4] = 122;entradas[5] = 29;entradas[6] = 1144;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 80;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 174;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 166;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 304;entradas[7] = 66;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 110;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 292;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 81;entradas[2] = 72;entradas[3] = 15;entradas[4] = 76;entradas[5] = 30;entradas[6] = 547;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 195;entradas[2] = 70;entradas[3] = 33;entradas[4] = 145;entradas[5] = 25;entradas[6] = 163;entradas[7] = 55;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 154;entradas[2] = 74;entradas[3] = 32;entradas[4] = 193;entradas[5] = 29;entradas[6] = 839;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 117;entradas[2] = 90;entradas[3] = 19;entradas[4] = 71;entradas[5] = 25;entradas[6] = 313;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 84;entradas[2] = 72;entradas[3] = 32;entradas[4] = 0;entradas[5] = 37;entradas[6] = 267;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 0;entradas[2] = 68;entradas[3] = 41;entradas[4] = 0;entradas[5] = 39;entradas[6] = 727;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 94;entradas[2] = 64;entradas[3] = 25;entradas[4] = 79;entradas[5] = 33;entradas[6] = 738;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 96;entradas[2] = 78;entradas[3] = 39;entradas[4] = 0;entradas[5] = 37;entradas[6] = 238;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 75;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 263;entradas[7] = 38;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 180;entradas[2] = 90;entradas[3] = 26;entradas[4] = 90;entradas[5] = 37;entradas[6] = 314;entradas[7] = 35;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 130;entradas[2] = 60;entradas[3] = 23;entradas[4] = 170;entradas[5] = 29;entradas[6] = 692;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 84;entradas[2] = 50;entradas[3] = 23;entradas[4] = 76;entradas[5] = 30;entradas[6] = 968;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 120;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 409;entradas[7] = 64;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 84;entradas[2] = 72;entradas[3] = 31;entradas[4] = 0;entradas[5] = 30;entradas[6] = 297;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 139;entradas[2] = 62;entradas[3] = 17;entradas[4] = 210;entradas[5] = 22;entradas[6] = 207;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 91;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 200;entradas[7] = 58;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 91;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 525;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 99;entradas[2] = 54;entradas[3] = 19;entradas[4] = 86;entradas[5] = 26;entradas[6] = 154;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 163;entradas[2] = 70;entradas[3] = 18;entradas[4] = 105;entradas[5] = 32;entradas[6] = 268;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 145;entradas[2] = 88;entradas[3] = 34;entradas[4] = 165;entradas[5] = 30;entradas[6] = 771;entradas[7] = 53;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 125;entradas[2] = 86;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 304;entradas[7] = 51;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 76;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 180;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 129;entradas[2] = 90;entradas[3] = 7;entradas[4] = 326;entradas[5] = 20;entradas[6] = 582;entradas[7] = 60;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 68;entradas[2] = 70;entradas[3] = 32;entradas[4] = 66;entradas[5] = 25;entradas[6] = 187;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 124;entradas[2] = 80;entradas[3] = 33;entradas[4] = 130;entradas[5] = 33;entradas[6] = 305;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 114;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 189;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 130;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 652;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 125;entradas[2] = 58;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 151;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 87;entradas[2] = 60;entradas[3] = 18;entradas[4] = 0;entradas[5] = 22;entradas[6] = 444;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 97;entradas[2] = 64;entradas[3] = 19;entradas[4] = 82;entradas[5] = 18;entradas[6] = 299;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 116;entradas[2] = 74;entradas[3] = 15;entradas[4] = 105;entradas[5] = 26;entradas[6] = 107;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 117;entradas[2] = 66;entradas[3] = 31;entradas[4] = 188;entradas[5] = 31;entradas[6] = 493;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 111;entradas[2] = 65;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 660;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 122;entradas[2] = 60;entradas[3] = 18;entradas[4] = 106;entradas[5] = 30;entradas[6] = 717;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 107;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 45;entradas[6] = 686;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 86;entradas[2] = 66;entradas[3] = 52;entradas[4] = 65;entradas[5] = 41;entradas[6] = 917;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 91;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 501;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 77;entradas[2] = 56;entradas[3] = 30;entradas[4] = 56;entradas[5] = 33;entradas[6] = 1251;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 132;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 302;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 105;entradas[2] = 90;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 197;entradas[7] = 46;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 57;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 22;entradas[6] = 735;entradas[7] = 67;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 127;entradas[2] = 80;entradas[3] = 37;entradas[4] = 210;entradas[5] = 36;entradas[6] = 804;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 129;entradas[2] = 92;entradas[3] = 49;entradas[4] = 155;entradas[5] = 36;entradas[6] = 968;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 100;entradas[2] = 74;entradas[3] = 40;entradas[4] = 215;entradas[5] = 39;entradas[6] = 661;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 128;entradas[2] = 72;entradas[3] = 25;entradas[4] = 190;entradas[5] = 32;entradas[6] = 549;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 90;entradas[2] = 85;entradas[3] = 32;entradas[4] = 0;entradas[5] = 35;entradas[6] = 825;entradas[7] = 56;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 84;entradas[2] = 90;entradas[3] = 23;entradas[4] = 56;entradas[5] = 40;entradas[6] = 159;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 88;entradas[2] = 78;entradas[3] = 29;entradas[4] = 76;entradas[5] = 32;entradas[6] = 365;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 186;entradas[2] = 90;entradas[3] = 35;entradas[4] = 225;entradas[5] = 35;entradas[6] = 423;entradas[7] = 37;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 187;entradas[2] = 76;entradas[3] = 27;entradas[4] = 207;entradas[5] = 44;entradas[6] = 1034;entradas[7] = 53;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 131;entradas[2] = 68;entradas[3] = 21;entradas[4] = 166;entradas[5] = 33;entradas[6] = 160;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 164;entradas[2] = 82;entradas[3] = 43;entradas[4] = 67;entradas[5] = 33;entradas[6] = 341;entradas[7] = 50;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 189;entradas[2] = 110;entradas[3] = 31;entradas[4] = 0;entradas[5] = 29;entradas[6] = 680;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 116;entradas[2] = 70;entradas[3] = 28;entradas[4] = 0;entradas[5] = 27;entradas[6] = 204;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 84;entradas[2] = 68;entradas[3] = 30;entradas[4] = 106;entradas[5] = 32;entradas[6] = 591;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 114;entradas[2] = 88;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 247;entradas[7] = 66;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 88;entradas[2] = 62;entradas[3] = 24;entradas[4] = 44;entradas[5] = 30;entradas[6] = 422;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 84;entradas[2] = 64;entradas[3] = 23;entradas[4] = 115;entradas[5] = 37;entradas[6] = 471;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 124;entradas[2] = 70;entradas[3] = 33;entradas[4] = 215;entradas[5] = 26;entradas[6] = 161;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 97;entradas[2] = 70;entradas[3] = 40;entradas[4] = 0;entradas[5] = 38;entradas[6] = 218;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 110;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 237;entradas[7] = 58;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 103;entradas[2] = 68;entradas[3] = 40;entradas[4] = 0;entradas[5] = 46;entradas[6] = 126;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 85;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 300;entradas[7] = 35;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 125;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 121;entradas[7] = 54;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 198;entradas[2] = 66;entradas[3] = 32;entradas[4] = 274;entradas[5] = 41;entradas[6] = 502;entradas[7] = 28;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 87;entradas[2] = 68;entradas[3] = 34;entradas[4] = 77;entradas[5] = 38;entradas[6] = 401;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 99;entradas[2] = 60;entradas[3] = 19;entradas[4] = 54;entradas[5] = 27;entradas[6] = 497;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 91;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 601;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 95;entradas[2] = 54;entradas[3] = 14;entradas[4] = 88;entradas[5] = 26;entradas[6] = 748;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 99;entradas[2] = 72;entradas[3] = 30;entradas[4] = 18;entradas[5] = 39;entradas[6] = 412;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 92;entradas[2] = 62;entradas[3] = 32;entradas[4] = 126;entradas[5] = 32;entradas[6] = 85;entradas[7] = 46;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 154;entradas[2] = 72;entradas[3] = 29;entradas[4] = 126;entradas[5] = 31;entradas[6] = 338;entradas[7] = 37;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 121;entradas[2] = 66;entradas[3] = 30;entradas[4] = 165;entradas[5] = 34;entradas[6] = 203;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 78;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 270;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 130;entradas[2] = 96;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 268;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 111;entradas[2] = 58;entradas[3] = 31;entradas[4] = 44;entradas[5] = 30;entradas[6] = 430;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 98;entradas[2] = 60;entradas[3] = 17;entradas[4] = 120;entradas[5] = 35;entradas[6] = 198;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 143;entradas[2] = 86;entradas[3] = 30;entradas[4] = 330;entradas[5] = 30;entradas[6] = 892;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 119;entradas[2] = 44;entradas[3] = 47;entradas[4] = 63;entradas[5] = 36;entradas[6] = 280;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 108;entradas[2] = 44;entradas[3] = 20;entradas[4] = 130;entradas[5] = 24;entradas[6] = 813;entradas[7] = 35;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 118;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 43;entradas[6] = 693;entradas[7] = 21;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 133;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 245;entradas[7] = 36;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 197;entradas[2] = 70;entradas[3] = 99;entradas[4] = 0;entradas[5] = 35;entradas[6] = 575;entradas[7] = 62;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 151;entradas[2] = 90;entradas[3] = 46;entradas[4] = 0;entradas[5] = 42;entradas[6] = 371;entradas[7] = 21;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 109;entradas[2] = 60;entradas[3] = 27;entradas[4] = 0;entradas[5] = 25;entradas[6] = 206;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 121;entradas[2] = 78;entradas[3] = 17;entradas[4] = 0;entradas[5] = 27;entradas[6] = 259;entradas[7] = 62;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 100;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 190;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 124;entradas[2] = 76;entradas[3] = 24;entradas[4] = 600;entradas[5] = 29;entradas[6] = 687;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 93;entradas[2] = 56;entradas[3] = 11;entradas[4] = 0;entradas[5] = 23;entradas[6] = 417;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 143;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 129;entradas[7] = 41;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 103;entradas[2] = 66;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 249;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 176;entradas[2] = 86;entradas[3] = 27;entradas[4] = 156;entradas[5] = 33;entradas[6] = 1154;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 73;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 21;entradas[6] = 342;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 111;entradas[2] = 84;entradas[3] = 40;entradas[4] = 0;entradas[5] = 47;entradas[6] = 925;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 112;entradas[2] = 78;entradas[3] = 50;entradas[4] = 140;entradas[5] = 39;entradas[6] = 175;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 132;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 402;entradas[7] = 44;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 82;entradas[2] = 52;entradas[3] = 22;entradas[4] = 115;entradas[5] = 29;entradas[6] = 1699;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 123;entradas[2] = 72;entradas[3] = 45;entradas[4] = 230;entradas[5] = 34;entradas[6] = 733;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 188;entradas[2] = 82;entradas[3] = 14;entradas[4] = 185;entradas[5] = 32;entradas[6] = 682;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 67;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 45;entradas[6] = 194;entradas[7] = 46;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 89;entradas[2] = 24;entradas[3] = 19;entradas[4] = 25;entradas[5] = 28;entradas[6] = 559;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 173;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 37;entradas[6] = 88;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 109;entradas[2] = 38;entradas[3] = 18;entradas[4] = 120;entradas[5] = 23;entradas[6] = 407;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 108;entradas[2] = 88;entradas[3] = 19;entradas[4] = 0;entradas[5] = 27;entradas[6] = 400;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 96;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 190;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 124;entradas[2] = 74;entradas[3] = 36;entradas[4] = 0;entradas[5] = 28;entradas[6] = 100;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 150;entradas[2] = 78;entradas[3] = 29;entradas[4] = 126;entradas[5] = 35;entradas[6] = 692;entradas[7] = 54;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 183;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 212;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 124;entradas[2] = 60;entradas[3] = 32;entradas[4] = 0;entradas[5] = 36;entradas[6] = 514;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 181;entradas[2] = 78;entradas[3] = 42;entradas[4] = 293;entradas[5] = 40;entradas[6] = 1258;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 92;entradas[2] = 62;entradas[3] = 25;entradas[4] = 41;entradas[5] = 20;entradas[6] = 482;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 152;entradas[2] = 82;entradas[3] = 39;entradas[4] = 272;entradas[5] = 42;entradas[6] = 270;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 111;entradas[2] = 62;entradas[3] = 13;entradas[4] = 182;entradas[5] = 24;entradas[6] = 138;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 106;entradas[2] = 54;entradas[3] = 21;entradas[4] = 158;entradas[5] = 31;entradas[6] = 292;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 174;entradas[2] = 58;entradas[3] = 22;entradas[4] = 194;entradas[5] = 33;entradas[6] = 593;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 168;entradas[2] = 88;entradas[3] = 42;entradas[4] = 321;entradas[5] = 38;entradas[6] = 787;entradas[7] = 40;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 105;entradas[2] = 80;entradas[3] = 28;entradas[4] = 0;entradas[5] = 33;entradas[6] = 878;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 138;entradas[2] = 74;entradas[3] = 26;entradas[4] = 144;entradas[5] = 36;entradas[6] = 557;entradas[7] = 50;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 106;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 207;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 117;entradas[2] = 96;entradas[3] = 0;entradas[4] = 0;entradas[5] = 29;entradas[6] = 157;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 68;entradas[2] = 62;entradas[3] = 13;entradas[4] = 15;entradas[5] = 20;entradas[6] = 257;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 112;entradas[2] = 82;entradas[3] = 24;entradas[4] = 0;entradas[5] = 28;entradas[6] = 1282;entradas[7] = 50;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 119;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 141;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 112;entradas[2] = 86;entradas[3] = 42;entradas[4] = 160;entradas[5] = 38;entradas[6] = 246;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 92;entradas[2] = 76;entradas[3] = 20;entradas[4] = 0;entradas[5] = 24;entradas[6] = 1698;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 183;entradas[2] = 94;entradas[3] = 0;entradas[4] = 0;entradas[5] = 41;entradas[6] = 1461;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 94;entradas[2] = 70;entradas[3] = 27;entradas[4] = 115;entradas[5] = 44;entradas[6] = 347;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 108;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 158;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 90;entradas[2] = 88;entradas[3] = 47;entradas[4] = 54;entradas[5] = 38;entradas[6] = 362;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 125;entradas[2] = 68;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 206;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 132;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 393;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 128;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 144;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 94;entradas[2] = 65;entradas[3] = 22;entradas[4] = 0;entradas[5] = 25;entradas[6] = 148;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 114;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 732;entradas[7] = 34;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 102;entradas[2] = 78;entradas[3] = 40;entradas[4] = 90;entradas[5] = 35;entradas[6] = 238;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 111;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 343;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 128;entradas[2] = 82;entradas[3] = 17;entradas[4] = 183;entradas[5] = 28;entradas[6] = 115;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 92;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 26;entradas[6] = 167;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 104;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 465;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 104;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 29;entradas[6] = 153;entradas[7] = 48;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 94;entradas[2] = 76;entradas[3] = 18;entradas[4] = 66;entradas[5] = 32;entradas[6] = 649;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 97;entradas[2] = 76;entradas[3] = 32;entradas[4] = 91;entradas[5] = 41;entradas[6] = 871;entradas[7] = 32;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 100;entradas[2] = 74;entradas[3] = 12;entradas[4] = 46;entradas[5] = 20;entradas[6] = 149;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 102;entradas[2] = 86;entradas[3] = 17;entradas[4] = 105;entradas[5] = 29;entradas[6] = 695;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 128;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 34;entradas[6] = 303;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 147;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 178;entradas[7] = 50;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 90;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 610;entradas[7] = 31;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 103;entradas[2] = 72;entradas[3] = 30;entradas[4] = 152;entradas[5] = 28;entradas[6] = 730;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 157;entradas[2] = 74;entradas[3] = 35;entradas[4] = 440;entradas[5] = 39;entradas[6] = 134;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 167;entradas[2] = 74;entradas[3] = 17;entradas[4] = 144;entradas[5] = 23;entradas[6] = 447;entradas[7] = 33;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 179;entradas[2] = 50;entradas[3] = 36;entradas[4] = 159;entradas[5] = 38;entradas[6] = 455;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 136;entradas[2] = 84;entradas[3] = 35;entradas[4] = 130;entradas[5] = 28;entradas[6] = 260;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 107;entradas[2] = 60;entradas[3] = 25;entradas[4] = 0;entradas[5] = 26;entradas[6] = 133;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 91;entradas[2] = 54;entradas[3] = 25;entradas[4] = 100;entradas[5] = 25;entradas[6] = 234;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 117;entradas[2] = 60;entradas[3] = 23;entradas[4] = 106;entradas[5] = 34;entradas[6] = 466;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 123;entradas[2] = 74;entradas[3] = 40;entradas[4] = 77;entradas[5] = 34;entradas[6] = 269;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 120;entradas[2] = 54;entradas[3] = 0;entradas[4] = 0;entradas[5] = 27;entradas[6] = 455;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 106;entradas[2] = 70;entradas[3] = 28;entradas[4] = 135;entradas[5] = 34;entradas[6] = 142;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 155;entradas[2] = 52;entradas[3] = 27;entradas[4] = 540;entradas[5] = 39;entradas[6] = 240;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 101;entradas[2] = 58;entradas[3] = 35;entradas[4] = 90;entradas[5] = 22;entradas[6] = 155;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 120;entradas[2] = 80;entradas[3] = 48;entradas[4] = 200;entradas[5] = 39;entradas[6] = 1162;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 127;entradas[2] = 106;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 190;entradas[7] = 51;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 80;entradas[2] = 82;entradas[3] = 31;entradas[4] = 70;entradas[5] = 34;entradas[6] = 1292;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 162;entradas[2] = 84;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 182;entradas[7] = 54;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 199;entradas[2] = 76;entradas[3] = 43;entradas[4] = 0;entradas[5] = 43;entradas[6] = 1394;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 167;entradas[2] = 106;entradas[3] = 46;entradas[4] = 231;entradas[5] = 38;entradas[6] = 165;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 145;entradas[2] = 80;entradas[3] = 46;entradas[4] = 130;entradas[5] = 38;entradas[6] = 637;entradas[7] = 40;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 115;entradas[2] = 60;entradas[3] = 39;entradas[4] = 0;entradas[5] = 34;entradas[6] = 245;entradas[7] = 40;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 112;entradas[2] = 80;entradas[3] = 45;entradas[4] = 132;entradas[5] = 35;entradas[6] = 217;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 145;entradas[2] = 82;entradas[3] = 18;entradas[4] = 0;entradas[5] = 33;entradas[6] = 235;entradas[7] = 70;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 111;entradas[2] = 70;entradas[3] = 27;entradas[4] = 0;entradas[5] = 28;entradas[6] = 141;entradas[7] = 40;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 98;entradas[2] = 58;entradas[3] = 33;entradas[4] = 190;entradas[5] = 34;entradas[6] = 430;entradas[7] = 43;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 154;entradas[2] = 78;entradas[3] = 30;entradas[4] = 100;entradas[5] = 31;entradas[6] = 164;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 165;entradas[2] = 68;entradas[3] = 26;entradas[4] = 168;entradas[5] = 34;entradas[6] = 631;entradas[7] = 49;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 99;entradas[2] = 58;entradas[3] = 10;entradas[4] = 0;entradas[5] = 25;entradas[6] = 551;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 68;entradas[2] = 106;entradas[3] = 23;entradas[4] = 49;entradas[5] = 36;entradas[6] = 285;entradas[7] = 47;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 123;entradas[2] = 100;entradas[3] = 35;entradas[4] = 240;entradas[5] = 57;entradas[6] = 880;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 91;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 36;entradas[6] = 587;entradas[7] = 68;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 195;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 328;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 156;entradas[2] = 86;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 230;entradas[7] = 53;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 93;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 35;entradas[6] = 263;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 121;entradas[2] = 52;entradas[3] = 0;entradas[4] = 0;entradas[5] = 36;entradas[6] = 127;entradas[7] = 25;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 101;entradas[2] = 58;entradas[3] = 17;entradas[4] = 265;entradas[5] = 24;entradas[6] = 614;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 56;entradas[2] = 56;entradas[3] = 28;entradas[4] = 45;entradas[5] = 24;entradas[6] = 332;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 162;entradas[2] = 76;entradas[3] = 36;entradas[4] = 0;entradas[5] = 50;entradas[6] = 364;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 95;entradas[2] = 64;entradas[3] = 39;entradas[4] = 105;entradas[5] = 45;entradas[6] = 366;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 125;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 32;entradas[6] = 536;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 136;entradas[2] = 82;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 640;entradas[7] = 69;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 129;entradas[2] = 74;entradas[3] = 26;entradas[4] = 205;entradas[5] = 33;entradas[6] = 591;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 130;entradas[2] = 64;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 314;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 107;entradas[2] = 50;entradas[3] = 19;entradas[4] = 0;entradas[5] = 28;entradas[6] = 181;entradas[7] = 29;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 140;entradas[2] = 74;entradas[3] = 26;entradas[4] = 180;entradas[5] = 24;entradas[6] = 828;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 144;entradas[2] = 82;entradas[3] = 46;entradas[4] = 180;entradas[5] = 46;entradas[6] = 335;entradas[7] = 46;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 107;entradas[2] = 80;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 856;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 158;entradas[2] = 114;entradas[3] = 0;entradas[4] = 0;entradas[5] = 42;entradas[6] = 257;entradas[7] = 44;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 121;entradas[2] = 70;entradas[3] = 32;entradas[4] = 95;entradas[5] = 39;entradas[6] = 886;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 129;entradas[2] = 68;entradas[3] = 49;entradas[4] = 125;entradas[5] = 39;entradas[6] = 439;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 90;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 191;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 142;entradas[2] = 90;entradas[3] = 24;entradas[4] = 480;entradas[5] = 30;entradas[6] = 128;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 169;entradas[2] = 74;entradas[3] = 19;entradas[4] = 125;entradas[5] = 30;entradas[6] = 268;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 99;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 25;entradas[6] = 253;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 127;entradas[2] = 88;entradas[3] = 11;entradas[4] = 155;entradas[5] = 35;entradas[6] = 598;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 118;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 45;entradas[6] = 904;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 122;entradas[2] = 76;entradas[3] = 27;entradas[4] = 200;entradas[5] = 36;entradas[6] = 483;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 125;entradas[2] = 78;entradas[3] = 31;entradas[4] = 0;entradas[5] = 28;entradas[6] = 565;entradas[7] = 49;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 168;entradas[2] = 88;entradas[3] = 29;entradas[4] = 0;entradas[5] = 35;entradas[6] = 905;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 129;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 39;entradas[6] = 304;entradas[7] = 41;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 110;entradas[2] = 76;entradas[3] = 20;entradas[4] = 100;entradas[5] = 28;entradas[6] = 118;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 80;entradas[2] = 80;entradas[3] = 36;entradas[4] = 0;entradas[5] = 40;entradas[6] = 177;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 115;entradas[2] = 0;entradas[3] = 0;entradas[4] = 0;entradas[5] = 0;entradas[6] = 261;entradas[7] = 30;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 127;entradas[2] = 46;entradas[3] = 21;entradas[4] = 335;entradas[5] = 34;entradas[6] = 176;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 164;entradas[2] = 78;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 148;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 93;entradas[2] = 64;entradas[3] = 32;entradas[4] = 160;entradas[5] = 38;entradas[6] = 674;entradas[7] = 23;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 158;entradas[2] = 64;entradas[3] = 13;entradas[4] = 387;entradas[5] = 31;entradas[6] = 295;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 126;entradas[2] = 78;entradas[3] = 27;entradas[4] = 22;entradas[5] = 30;entradas[6] = 439;entradas[7] = 40;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 129;entradas[2] = 62;entradas[3] = 36;entradas[4] = 0;entradas[5] = 41;entradas[6] = 441;entradas[7] = 38;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 134;entradas[2] = 58;entradas[3] = 20;entradas[4] = 291;entradas[5] = 26;entradas[6] = 352;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 102;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 121;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 187;entradas[2] = 50;entradas[3] = 33;entradas[4] = 392;entradas[5] = 34;entradas[6] = 826;entradas[7] = 34;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 173;entradas[2] = 78;entradas[3] = 39;entradas[4] = 185;entradas[5] = 34;entradas[6] = 970;entradas[7] = 31;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 94;entradas[2] = 72;entradas[3] = 18;entradas[4] = 0;entradas[5] = 23;entradas[6] = 595;entradas[7] = 56;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 108;entradas[2] = 60;entradas[3] = 46;entradas[4] = 178;entradas[5] = 36;entradas[6] = 415;entradas[7] = 24;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 97;entradas[2] = 76;entradas[3] = 27;entradas[4] = 0;entradas[5] = 36;entradas[6] = 378;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 83;entradas[2] = 86;entradas[3] = 19;entradas[4] = 0;entradas[5] = 29;entradas[6] = 317;entradas[7] = 34;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 114;entradas[2] = 66;entradas[3] = 36;entradas[4] = 200;entradas[5] = 38;entradas[6] = 289;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 149;entradas[2] = 68;entradas[3] = 29;entradas[4] = 127;entradas[5] = 29;entradas[6] = 349;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 117;entradas[2] = 86;entradas[3] = 30;entradas[4] = 105;entradas[5] = 39;entradas[6] = 251;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 111;entradas[2] = 94;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 265;entradas[7] = 45;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 112;entradas[2] = 78;entradas[3] = 40;entradas[4] = 0;entradas[5] = 39;entradas[6] = 236;entradas[7] = 38;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 116;entradas[2] = 78;entradas[3] = 29;entradas[4] = 180;entradas[5] = 36;entradas[6] = 496;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 141;entradas[2] = 84;entradas[3] = 26;entradas[4] = 0;entradas[5] = 32;entradas[6] = 433;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 175;entradas[2] = 88;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 326;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 92;entradas[2] = 52;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 141;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 130;entradas[2] = 78;entradas[3] = 23;entradas[4] = 79;entradas[5] = 28;entradas[6] = 323;entradas[7] = 34;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 120;entradas[2] = 86;entradas[3] = 0;entradas[4] = 0;entradas[5] = 28;entradas[6] = 259;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 174;entradas[2] = 88;entradas[3] = 37;entradas[4] = 120;entradas[5] = 45;entradas[6] = 646;entradas[7] = 24;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 106;entradas[2] = 56;entradas[3] = 27;entradas[4] = 165;entradas[5] = 29;entradas[6] = 426;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 105;entradas[2] = 75;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 560;entradas[7] = 53;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 95;entradas[2] = 60;entradas[3] = 32;entradas[4] = 0;entradas[5] = 35;entradas[6] = 284;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 126;entradas[2] = 86;entradas[3] = 27;entradas[4] = 120;entradas[5] = 27;entradas[6] = 515;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 65;entradas[2] = 72;entradas[3] = 23;entradas[4] = 0;entradas[5] = 32;entradas[6] = 600;entradas[7] = 42;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 99;entradas[2] = 60;entradas[3] = 17;entradas[4] = 160;entradas[5] = 37;entradas[6] = 453;entradas[7] = 21;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 102;entradas[2] = 74;entradas[3] = 0;entradas[4] = 0;entradas[5] = 40;entradas[6] = 293;entradas[7] = 42;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 11;entradas[1] = 120;entradas[2] = 80;entradas[3] = 37;entradas[4] = 150;entradas[5] = 42;entradas[6] = 785;entradas[7] = 48;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 102;entradas[2] = 44;entradas[3] = 20;entradas[4] = 94;entradas[5] = 31;entradas[6] = 400;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 109;entradas[2] = 58;entradas[3] = 18;entradas[4] = 116;entradas[5] = 29;entradas[6] = 219;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 140;entradas[2] = 94;entradas[3] = 0;entradas[4] = 0;entradas[5] = 33;entradas[6] = 734;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 13;entradas[1] = 153;entradas[2] = 88;entradas[3] = 37;entradas[4] = 140;entradas[5] = 41;entradas[6] = 1174;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 12;entradas[1] = 100;entradas[2] = 84;entradas[3] = 33;entradas[4] = 105;entradas[5] = 30;entradas[6] = 488;entradas[7] = 46;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 147;entradas[2] = 94;entradas[3] = 41;entradas[4] = 0;entradas[5] = 49;entradas[6] = 358;entradas[7] = 27;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 81;entradas[2] = 74;entradas[3] = 41;entradas[4] = 57;entradas[5] = 46;entradas[6] = 1096;entradas[7] = 32;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 187;entradas[2] = 70;entradas[3] = 22;entradas[4] = 200;entradas[5] = 36;entradas[6] = 408;entradas[7] = 36;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 162;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 24;entradas[6] = 178;entradas[7] = 50;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 4;entradas[1] = 136;entradas[2] = 70;entradas[3] = 0;entradas[4] = 0;entradas[5] = 31;entradas[6] = 1182;entradas[7] = 22;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 121;entradas[2] = 78;entradas[3] = 39;entradas[4] = 74;entradas[5] = 39;entradas[6] = 261;entradas[7] = 28;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 3;entradas[1] = 108;entradas[2] = 62;entradas[3] = 24;entradas[4] = 0;entradas[5] = 26;entradas[6] = 223;entradas[7] = 25;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 181;entradas[2] = 88;entradas[3] = 44;entradas[4] = 510;entradas[5] = 43;entradas[6] = 222;entradas[7] = 26;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 8;entradas[1] = 154;entradas[2] = 78;entradas[3] = 32;entradas[4] = 0;entradas[5] = 32;entradas[6] = 443;entradas[7] = 45;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 128;entradas[2] = 88;entradas[3] = 39;entradas[4] = 110;entradas[5] = 37;entradas[6] = 1057;entradas[7] = 37;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 7;entradas[1] = 137;entradas[2] = 90;entradas[3] = 41;entradas[4] = 0;entradas[5] = 32;entradas[6] = 391;entradas[7] = 39;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 0;entradas[1] = 123;entradas[2] = 72;entradas[3] = 0;entradas[4] = 0;entradas[5] = 36;entradas[6] = 258;entradas[7] = 52;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 106;entradas[2] = 76;entradas[3] = 0;entradas[4] = 0;entradas[5] = 38;entradas[6] = 197;entradas[7] = 26;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 6;entradas[1] = 190;entradas[2] = 92;entradas[3] = 0;entradas[4] = 0;entradas[5] = 36;entradas[6] = 278;entradas[7] = 66;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 88;entradas[2] = 58;entradas[3] = 26;entradas[4] = 16;entradas[5] = 28;entradas[6] = 766;entradas[7] = 22;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 170;entradas[2] = 74;entradas[3] = 31;entradas[4] = 0;entradas[5] = 44;entradas[6] = 403;entradas[7] = 43;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 9;entradas[1] = 89;entradas[2] = 62;entradas[3] = 0;entradas[4] = 0;entradas[5] = 23;entradas[6] = 142;entradas[7] = 33;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 10;entradas[1] = 101;entradas[2] = 76;entradas[3] = 48;entradas[4] = 180;entradas[5] = 33;entradas[6] = 171;entradas[7] = 63;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 2;entradas[1] = 122;entradas[2] = 70;entradas[3] = 27;entradas[4] = 0;entradas[5] = 37;entradas[6] = 340;entradas[7] = 27;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 5;entradas[1] = 121;entradas[2] = 72;entradas[3] = 23;entradas[4] = 112;entradas[5] = 26;entradas[6] = 245;entradas[7] = 30;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 126;entradas[2] = 60;entradas[3] = 0;entradas[4] = 0;entradas[5] = 30;entradas[6] = 349;entradas[7] = 47;$display("Resultado: TRUE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();
entradas[0] = 1;entradas[1] = 93;entradas[2] = 70;entradas[3] = 31;entradas[4] = 0;entradas[5] = 30;entradas[6] = 315;entradas[7] = 23;$display("Resultado: FALSE");
for (i = 0; i < N; i = i + 1)
    entradas[i] = entradas[i]<<16;
mlp();


		
		
        $finish;
    end

task mlp;
	
		reg signed [31:0] f[0:N];
		reg signed [63:0] aux64;
		reg signed [31:0] y;
		
		parameter signed [31:0] zero = 0;
		parameter signed [31:0] um = 32'b0000000000000001_0000000000000000;

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
					aux64 = entradas[j] * w[j][i];
					f[i] = f[i] + aux64[47:16];
					//$display("faux%d: %f \n", i, $itor(faux[i])*sf);
					//$display("f%d: %f \n", i, $itor(f[i])*sf16);
				end
				f[i] = f[i] + w[N][i]; //bias
				
				/* Relu com limite superior*/
				if(f[i] > um)
					f[i] = um;
				else if(f[i] < zero)
					f[i] = zero;
			end

			/* CAMADA SAIDA */
			y = zero;
			for(i = 0; i < NEURONIOS; i = i + 1)
			begin
				aux64 = f[i] * v[i];
				y = y + aux64[47:16];
			end
			y = y + v[N];
				 
			if(y > $signed(32'b0000000000000000_1001100110011001))      //y > 0.6
			begin
			    $display("Resultado: TRUE\n");
			    resultado = 3;              //y = 3;
		    end
			else if(y > $signed(32'b0000000000000000_1000000000000000)) // 0.6 > y > 0.5
			begin
			    $display("Resultado: TRUE\n");
				resultado = 2;              //y = 2;
            end
			else if(y > $signed(32'b0000000000000000_0110011001100110)) // 0.5 > y > 0.4
			begin
			    $display("Resultado: FALSE\n");
				resultado = 1;              //y = 1;
			end
			else                        //y < 0.4
			begin
			    $display("Resultado: FALSE\n");
				resultado = 0;              //y = 0;
			end
			
			
			//$display("%f \n %b", $itor(y)*sf, y);//y = 0;
		end
	endtask
	
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
endmodule