
module decryption_engine_tb
#(
    parameter WIDTH      = 128,   // AES Input (Same for key)
    parameter DEPTH      = 2048,  // Needs to be decided
    parameter INIT       = 0, // Initialize memory to 0s, if INIT is true
    parameter AES_ROUNDS = 10
)
(

);

reg                              clock = 0;
reg                              reset;
reg [WIDTH-1:0]                  encr_data;
reg                              encr_valid;
wire [WIDTH-1:0]                  dec_data;
wire                              dec_valid;
wire [`CLOG2(DEPTH)-1:0]          dec_addr;

wire                            ready; 


reg                              init;
reg                              start;
wire                              done;
wire                              done_init;
reg [WIDTH-1:0]                  key;


decryption_engine #(.WIDTH(WIDTH), .DEPTH(DEPTH), .AES_ROUNDS(AES_ROUNDS)) 
DUT
(
    .clock(clock),
    .reset(reset),
    .encr_data(encr_data),
    .encr_valid(encr_valid),
    .dec_data(dec_data),
    .dec_valid(dec_valid),
    .dec_addr(dec_addr),
    .ready(ready),
    .init(init),
    .start(start),
    .done(done),
    .done_init(done_init),
    .key(key)
);



initial
begin

    $dumpfile("decryption_engine_tb.vcd");
    $dumpvars(0,decryption_engine_tb);
    init <= 0;
    start <= 0;
    encr_valid <= 0;
    reset <= 1;
    encr_data <= 0;
    #200
    
    reset <= 0;
    
//    @(posedge ready) // if ready was working you could wait for ready
    #10
        
    init <= 1;
    key <= {(128){1'b0}};

    $monitor(,$time, "init=%b,done_init=%b,start=%b,encr_valid=%b,dec_data=%b,dec_valid=%b,ready=%b",init,done_init,start,encr_valid,dec_data,dec_valid,ready);
    
    
    
    // #10
@(posedge done_init);
    
    init <= 0; // added init = 0 here because your done_init is received with in one clock cycle otherwise move "#10 init <= 0;" before  @(posedge done_init);
    
    //key scheduling completed, now start decryption
    #10
    
    
    
    encr_valid <= 1;
    encr_data <= {(128){1'b1}}; // example encrypted data = 0xffffffffffffffffffffffffffffffff
   
    #10
    encr_valid <= 0;

    start <= 1;

    #10 
   
    start <= 0;

    #1000
    $finish;

   
   @(posedge done); // waiting for decryption to finish
    
    #100
    $finish;
    
end


always #5 clock = ~clock; 




endmodule