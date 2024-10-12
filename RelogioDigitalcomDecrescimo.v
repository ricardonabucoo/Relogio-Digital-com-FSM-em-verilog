module counter_clock_fsm(clk, rst, set, inc, cen, blk, dp7_1, dp7_2, dp7_3, dp7_4, leds); 
   
    input       clk;        
    input       rst;       
    input       set;      
    input       inc;        
    input       cen;       
    
   
    output     [6:0] dp7_1; // saída para o primeiro display de 7 segmentos (minutos unidade)
    output     [6:0] dp7_2; 
    output     [6:0] dp7_3; 
    output     [6:0] dp7_4; 
    output reg [9:0] leds; 
    
    supply1 blk ; 

    // Definição de estados da FSM
    `define IDLE       2'b00 
    `define SET_HOUR   2'b01 
    `define SET_MINUTE 2'b10
 
    reg [3:0] cnt1;         
    reg [2:0] cnt2;       
    reg [3:0] cnt3;        
    reg [1:0] cnt4;         
    reg [5:0] seconds;      

    reg [1:0] state;       
    reg [1:0] next_state; 
    reg set_last;          
    reg inc_last;          

    // Inicializa o estado
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt1 <= 4'b0000; 
            cnt2 <= 3'b000;  
            cnt3 <= 4'b0000; 
            cnt4 <= 2'b00;   // Dezena de horas
            seconds <= 6'b000000; // Contador de segundos
            state <= `IDLE;        // Estado inicial
            leds <= 10'b0000000000; // Inicializa os LEDs apagados
        end else begin
            state <= next_state;  // Atualiza o estado

            // Atualiza o estado dos botões
            set_last <= set;  // Atualiza o valor do botão set
            inc_last <= inc;  // Atualiza o valor do botão inc

            // Detecta borda de subida para o botão set (alternar modos)
            if (set && !set_last) begin
                case (state)
                    `IDLE:       next_state <= `SET_HOUR;   
                    `SET_HOUR:  next_state <= `SET_MINUTE;  
                    `SET_MINUTE: next_state <= `IDLE;       
                endcase
            end

            
            
if (inc && !inc_last) begin
    case (state)
        `SET_HOUR: begin
            // Ajustar horas
            if (!cen) begin  // Lógica de acréscimo 
                if (cnt4 == 2'b10 && cnt3 == 4'b0011) begin // Limite 23 
                    cnt3 <= 4'b0000;
                    cnt4 <= 2'b00;
                end else if (cnt3 == 4'b1001) begin
                    cnt3 <= 4'b0000;
                    cnt4 <= cnt4 + 1;
                end else begin
                    cnt3 <= cnt3 + 1;
                end
            end else begin  // Lógica de decréscimo 
                if (cnt4 == 2'b00 && cnt3 == 4'b0000) begin // Limite 0 horas
                    cnt3 <= 4'b1001; // 9 horas unidade
                    cnt4 <= 2'b10;   // 2 horas dezena (23 horas total)
                end else if (cnt3 == 4'b0000) begin
                    cnt3 <= 4'b1001;  
                    cnt4 <= cnt4 - 1; 
                end else begin
                    cnt3 <= cnt3 - 1; 
                end
            end
        end
        `SET_MINUTE: begin
            
            if (!cen) begin  // Lógica de acréscimo (cen == 0)
                if (cnt2 == 3'b101 && cnt1 == 4'b1001) begin 
                    cnt1 <= 4'b0000;
                    cnt2 <= 3'b000;
                end else if (cnt1 == 4'b1001) begin
                    cnt1 <= 4'b0000;
                    cnt2 <= cnt2 + 1;
                end else begin
                    cnt1 <= cnt1 + 1;
                end
            end else begin  // Lógica de decréscimo (cen == 1)
                if (cnt2 == 3'b000 && cnt1 == 4'b0000) begin
                    cnt1 <= 4'b1001; 
                    cnt2 <= 3'b101;  
                end else if (cnt1 == 4'b0000) begin
                    cnt1 <= 4'b1001;  // Reseta unidade para 9
                    cnt2 <= cnt2 - 1; 
                end else begin
                    cnt1 <= cnt1 - 1; 
                end
            end
        end
    endcase
end


            // Lógica de contagem normal no estado IDLE
            if (state == `IDLE) begin
                if (!cen) begin
                    // Contagem de segundos
                    if (seconds == 6'd59) begin
                        seconds <= 6'b000000;
                        // Incrementa os minutos quando os segundos chegam a 59
                        if (cnt1 == 4'b1001) begin
                            cnt1 <= 4'b0000;
                            if (cnt2 == 3'b101) begin
                                cnt2 <= 3'b000;
                                // Incrementa as horas quando os minutos chegam a 59
                                if (cnt3 == 4'b1001) begin
                                    cnt3 <= 4'b0000;
                                    if (cnt4 == 2'b10) begin
                                        cnt4 <= 2'b00; 
                                    end else begin
                                        cnt4 <= cnt4 + 1;
                                    end
                                end else begin
                                    cnt3 <= cnt3 + 1;
                                end
                            end else begin
                                cnt2 <= cnt2 + 1;
                            end
                        end else begin
                            cnt1 <= cnt1 + 1;
                        end
                    end else begin
                        seconds <= seconds + 1; // Incrementa segundos
                    end

                    // Atualiza LEDs  (1 LED a cada 6 segundos)
                     case (seconds)
                        6'd6: leds <= 10'b0000000001;
                        6'd12: leds <= 10'b0000000011;
                        6'd18: leds <= 10'b0000000111;
                        6'd24: leds <= 10'b0000001111;
                        6'd30: leds <= 10'b0000011111;
                        6'd36: leds <= 10'b0000111111;
                        6'd42: leds <= 10'b0001111111;
                        6'd48: leds <= 10'b0011111111;
                        6'd54: leds <= 10'b0111111111;
                        6'd60: leds <= 10'b1111111111;
                        default: leds <= 10'b0000000000; 
                    endcase
                end
            end
        end
    end

    
    nibble2display NIBBLE2DP7_1(
        .nibble(cnt1),
        .display7seg(dp7_1));

    
    nibble2display_ate5 NIBBLE2DP7_2(
        .nibble(cnt2),
        .display7seg(dp7_2));

    
    nibble2display NIBBLE2DP7_3(
        .nibble(cnt3),
        .display7seg(dp7_3));

    
    nibble2display_ate2 NIBBLE2DP7_4(
        .nibble(cnt4),
        .display7seg(dp7_4));

endmodule

// Módulo nibble2display para números de 0 a 9
module nibble2display(nibble, display7seg);
    input [3:0] nibble;
    output [6:0] display7seg;

    assign display7seg =
                (nibble == 4'b0000)  ?  7'b1111110 :   // 0
                (nibble == 4'b0001)  ?  7'b0110000 :   // 1
                (nibble == 4'b0010)  ?  7'b1101101 :   // 2
                (nibble == 4'b0011)  ?  7'b1111001 :   // 3
                (nibble == 4'b0100)  ?  7'b0110011 :   // 4
                (nibble == 4'b0101)  ?  7'b1011011 :   // 5
                (nibble == 4'b0110)  ?  7'b1011111 :   // 6
                (nibble == 4'b0111)  ?  7'b1110000 :   // 7
                (nibble == 4'b1000)  ?  7'b1111111 :   // 8
                (nibble == 4'b1001)  ?  7'b1111011 :   // 9
                                        7'b0000000;    // Desliga 
endmodule:nibble2display


module nibble2display_ate5(nibble, display7seg);
    input [2:0] nibble;
    output [6:0] display7seg;

    assign display7seg =
                (nibble == 3'b000)  ?  7'b1111110 :   // 0
                (nibble == 3'b001)  ?  7'b0110000 :   // 1
                (nibble == 3'b010)  ?  7'b1101101 :   // 2
                (nibble == 3'b011)  ?  7'b1111001 :   // 3
                (nibble == 3'b100)  ?  7'b0110011 :   // 4
                (nibble == 3'b101)  ?  7'b1011011 :   // 5
                                      7'b0000000;     // Desliga 
endmodule:nibble2display_ate5


module nibble2display_ate2(nibble, display7seg);
    input [1:0] nibble;
    output [6:0] display7seg;

    assign display7seg =
                (nibble == 2'b00)  ?  7'b1111110 :   // 0
                (nibble == 2'b01)  ?  7'b0110000 :   // 1
                (nibble == 2'b10)  ?  7'b1101101 :   // 2
                                    7'b0000000;     // Desliga 
endmodule:nibble2display_ate2

