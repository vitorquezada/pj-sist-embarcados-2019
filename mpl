module mlp; // multilayer perceptron

 parameter signed [3:0] NEURONIOS = 4'b0111; /* 7 neuronios camada intermediaria */
 parameter N = 6; /* numero entradas */
 reg signed [3:0] i;
 reg signed [15:0] x[0:N];
 reg signed [31:0] f[0:N];
 reg signed [31:0] y;
 reg signed [4:0] result;
 reg signed [15:0]  w [0:N][0:NEURONIOS]; /* camada intermediaria */
 reg signed [15:0]  v [0:NEURONIOS]; /* camada saida */
 
 parameter signed [15:0] zero= 8'b0000_0000;
 parameter signed [15:0] um= 8'b0111_0000;

  initial 
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
      $finish ;
    end
endmodule
