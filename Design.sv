module ALU(oper, rst, clk, in1, in2, out);
  input clk, rst;
  input [1:0] oper;
  input [3:0] in1, in2;
  output reg [4:0] out;

  always @(posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin
      case (oper)
        2'b00: out <= in1 + in2;   
        2'b01: out <= in1 * in2;   
        2'b10: out <= in1 - in2;   
        2'b11: out <= (in2 != 0) ? in1 / in2 : 0; 
        default: out <= 0;         
      endcase
    end
  end
endmodule
