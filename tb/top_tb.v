
module top_tb
#(
  parameter BITMAP_MEM_WIDTH        = 128,  // Same as decryption memory input width
  parameter MAX_BITMAP_MEM_DEPTH    = 2048, // Depends on max expected bitmap size
  parameter BITMAP_MEM_INIT         = 0,    // Initialize memory to 0s, if INIT is true

  parameter AES_KEY_SIZE            = 128,
  parameter AES_ROUNDS              = 10,

  parameter IN_BITMAP_WIDTH         = 32,
  parameter IN_SIZE_WIDTH           = 32,

  parameter OUT_DATA_WIDTH          = 32,
  parameter OUT_SIZE_WIDTH          = 32,

  parameter NUM_SWITCHES            = 7,
  
//  parameter BITMAP_FILE             = "DUMMY_ENCRYPTED_DATA.mem"
  parameter BITMAP_FILE             = ""
)
(

);

reg                              clock = 0;
reg                              reset;
  // Control signals input to the switch control module
reg                                     sync;
reg                                     init;
//reg                                     init_key;
reg                                     start_signal;
wire                                    done_signal;
//wire                                    done_init_key;
  // Signals for input AES key
reg  [AES_KEY_SIZE-1:0]                 in_key;
  
  // Signals for input bitmap
reg  [IN_BITMAP_WIDTH-1:0]              in_bitmap;
//  input  [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] in_bitmap_addr,
reg                                     in_bitmap_valid;
reg  [IN_SIZE_WIDTH-1:0]                in_bitmap_size;
  
  // Signals for output bitmap
wire [OUT_DATA_WIDTH-1:0]               out_bitmap;
wire                                    out_bitmap_valid;
wire [OUT_SIZE_WIDTH-1:0]               out_bitmap_size;

  // Signals for switches
wire [NUM_SWITCHES-1:0]                 out_to_switches;

top #(.BITMAP_FILE(BITMAP_FILE))
DUT
(
    .clock(clock),
    .reset(reset),
    .sync(sync),
    .init(init),
//    .init_key(init_key),
//    .done_init_key(done_init_key),
    .start_signal(start_signal),
    .done_signal(done_signal),
    .in_key(in_key),
    .in_bitmap(in_bitmap),
    .in_bitmap_valid(in_bitmap_valid),
    .in_bitmap_size(in_bitmap_size),
    .out_bitmap(out_bitmap),
    .out_bitmap_valid(out_bitmap_valid),
    .out_bitmap_size(out_bitmap_size),
    
    .in_rd_clock(clock),
    .in_rd_out_to_switches(0),
    .out_to_switches(out_to_switches),

    .in_trng_seed(0),
    .in_trng_seed_addr(0),
    .in_trng_seed_wen(0)
);


integer start_time = 0;

initial
begin

    $dumpfile("top_tb.vcd");
    $dumpvars(0,top_tb);
    init <= 0;
    start_signal <= 0;
    reset <= 1;
    #200
    
    reset <= 0;
    
//    @(posedge ready) // if ready was working you could wait for ready
    #10
   


//    $monitor(,$time, "init=%b,done_init=%b,start=%b,dec_data=%b,dec_valid=%b,ready=%b",init,done_init,start,dec_data,dec_valid,ready);
        
    init <= 1;    
    
    #10 
    init <= 0;
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10  
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10  
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10  
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    
    in_bitmap_valid <= 1; in_bitmap <=  32'hbfffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hfffffffe; #10 
    
    in_bitmap_valid <= 1; in_bitmap <=  32'hdfffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hfffffffb; #10 
    
    in_bitmap_valid <= 1; in_bitmap <=  32'hefffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hffffffff; #10 
    in_bitmap_valid <= 1; in_bitmap <=  32'hfffffffb; #10
    
    in_bitmap_valid <= 0; 
    
    
    in_key <= 1; //{(128){1'b0}};
    
    start_time = $time;    
    start_signal <= 1;
    in_bitmap_size <= 512;

    #10 
   
    start_signal <= 0;

   
   @(posedge DUT.dec_done); // waiting for decryption to finish
    
    $display("Time taken to decrypt the bitmap", ($time - start_time - 5)/10);
   
   @(posedge done_signal);
    $display("Time taken to decrypt and fifo load the bitmap", ($time - start_time - 5)/10);
    #100
    $finish;
    
end


always #5 clock = ~clock; 




endmodule