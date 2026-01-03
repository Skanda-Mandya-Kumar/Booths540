module booth_multiplier (
    A, B, reset, clock, start, P, ready
);

    input  signed [3:0] A;      // multiplicand
    input  signed [3:0] B;      // multiplier
    input               reset;
    input               clock;
    input               start;

    output reg signed [7:0] P;  // product
    output reg              ready;

    // Booth register: {ACC[3:0], Q[3:0], Q_1}
    reg signed [8:0] booth;
    reg [2:0] count;
    reg [1:0] state;

    parameter IDLE = 2'd0,
              RUN  = 2'd1,
              DONE = 2'd2;

    reg signed [8:0] temp;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            booth <= 9'sd0;
            count <= 3'd0;
            P     <= 8'sd0;
            ready <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)

                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        booth <= {4'sd0, B, 1'b0}; // ACC=0, Q=B, Q-1=0
                        count <= 3'd4;            // 4 iterations
                        state <= RUN;
                    end
                end

                RUN: begin
                    temp = booth;

                    case (booth[1:0])
                        2'b01: temp[8:5] = booth[8:5] + A;
                        2'b10: temp[8:5] = booth[8:5] - A;
                        default: ;
                    endcase

                    booth <= temp >>> 1; // arithmetic shift right
                    count <= count - 1;

                    if (count == 3'd1)
                        state <= DONE;
                end

                DONE: begin
                    P     <= booth[8:1]; // final product
                    ready <= 1'b1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
