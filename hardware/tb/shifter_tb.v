
module shifter_tb
#(
  parameter IN_WIDTH        = 128,  
  parameter OUT_WIDTH        = 7
)
(

);

reg                              clock = 0;
reg                              reset;
reg                              start;
reg                              fifo_full;
reg [IN_WIDTH-1:0]               long_vector_in;
wire [OUT_WIDTH-1:0]             short_vector_out;
wire                             short_vector_out_valid;
wire                             done;

shifter #(.IN_WIDTH(IN_WIDTH), .OUT_WIDTH(OUT_WIDTH))
DUT
(
    .clock(clock),
    .reset(reset),
    .start(start),
    .fifo_full(fifo_full),
    .long_vector_in(long_vector_in),
    .short_vector_out(short_vector_out),
    .short_vector_out_valid(short_vector_out_valid),
    .done(done)
);


integer start_time = 0;

initial
begin

    reset <= 1;
    start <= 0;
    fifo_full <= 0;
    long_vector_in <= 0;
    
    #200
    
    reset <= 0;
    #100
    start <=1;
    long_vector_in <= {7'b0000100,7'b1010000,7'b1011010,7'b0010011,7'b0000001,7'b0101100,7'b1000011,7'b1001110,7'b0010101,7'b1001001,7'b0001001,7'b1011010,7'b0011000,7'b0001110,7'b1110010,7'b1101110,7'b0101001,7'b1100000,3'b011};

    #10
    start <= 0;

    #60
    fifo_full <= 1;
    
    #100
    fifo_full <= 0;

   @(posedge done);
    $display("Time taken to shift full vector", ($time - start_time - 5)/10);
    if (check_vector == long_vector_in[IN_WIDTH-1:IN_WIDTH%OUT_WIDTH]) begin
      $display("Test passed");
    end
    else begin
      $display("Test failed");
    end
    #1000
    $finish;
    
end


always #5 clock = ~clock; 

//sanity check
reg [IN_WIDTH-IN_WIDTH%OUT_WIDTH-1:0] check_vector;
always @(posedge clock)
begin
  if (start) begin
    check_vector <= 0;
  end
  else if (short_vector_out_valid) begin
    check_vector <= {check_vector[IN_WIDTH-IN_WIDTH%OUT_WIDTH-OUT_WIDTH-1:0], short_vector_out};
  end
end

wire test_output_correct;
assign test_output_correct = check_vector == long_vector_in[IN_WIDTH-1:IN_WIDTH%OUT_WIDTH];


endmodule