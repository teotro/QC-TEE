// shifter that shift out OUT_WIDTH bits per clock cycle while checking for fifo_full condition


module shifter
#(
  parameter IN_WIDTH     = 128,  // input width
  parameter OUT_WIDTH    = 7 // output width
)
(
  // Clock and reset signals
  input    wire                                 clock,
  input    wire                                 reset,
  input    wire                                 start,
  input    wire                                 fifo_full,
  input    wire [IN_WIDTH-1:0]                  long_vector_in,
  output   wire [OUT_WIDTH-1:0]                 short_vector_out,
  output   wire                                 short_vector_out_valid,
  output   reg                                  done
);

reg [127:0] shifter_vec;
always@(posedge clock)
begin
  if (start) begin
    shifter_vec <= long_vector_in;
  end
  else if (state == S_SHIFT && ~fifo_full) begin
    shifter_vec <= {shifter_vec[IN_WIDTH-OUT_WIDTH-1:0], {(OUT_WIDTH){1'b0}}};
  end
end

parameter S_WAIT_START = 0;
parameter S_SHIFT = 1;
reg state;
reg [`CLOG2(IN_WIDTH/OUT_WIDTH):0] count;

always@(posedge clock)
begin
  if (reset) begin
    state <= S_WAIT_START;
    done <= 0;
    count <= 0;
  end
  else begin
    if (state == S_WAIT_START) begin 
      if (start) begin
        state <= S_SHIFT;
      end
      count <= 0;
      done <= 0;
    end
    else if (state == S_SHIFT) begin
      if (count == IN_WIDTH/OUT_WIDTH) begin
        state <= S_WAIT_START;
        done <= 1;
        count <= 0;
      end
      else begin
        if (~fifo_full) begin
          count <= count + 1;
        end
      end
    end
  end
end

  assign short_vector_out = shifter_vec[IN_WIDTH-1:IN_WIDTH-OUT_WIDTH];
  assign short_vector_out_valid = state == S_SHIFT && ~fifo_full && count < IN_WIDTH/OUT_WIDTH;

endmodule
