
module dec_x_mem_tb
#(
    parameter BITMAP_MEM_WIDTH      = 128,   // AES Input (Same for key)
    parameter MAX_BITMAP_MEM_DEPTH      = 2048   // Needs to be decided
)
(

);

reg                              clock = 0;
reg                              reset;
wire [BITMAP_MEM_WIDTH-1:0]                  encr_data;
wire [BITMAP_MEM_WIDTH-1:0]                  dec_data;
wire                              dec_valid;
wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]          dec_addr;
reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]          bit_map_depth;

wire                            ready; 


reg                              init;
reg                              start;
wire                              done;
wire                              done_init;
reg [BITMAP_MEM_WIDTH-1:0]                  key;

wire dec_eng_ready;

decryption_engine #(.MAX_BITMAP_MEM_DEPTH(MAX_BITMAP_MEM_DEPTH), .MAX_BITMAP_MEM_DEPTH(MAX_BITMAP_MEM_DEPTH)) 
DUT
(
    .clock(clock),
    .reset(reset),
    .bit_map_depth(bit_map_depth),
    .encr_data(encr_data),
    .dec_data(dec_data),
    .dec_valid(dec_valid),
    .dec_addr(dec_addr),
    .dec_eng_ready(dec_eng_ready),
    .init(init),
    .start(start),
    .done(done),
    .done_init(done_init),
    .key(key)
);


wire [BITMAP_MEM_WIDTH-1:0]    data_0;
wire [BITMAP_MEM_WIDTH-1:0]    data_1;
wire [BITMAP_MEM_WIDTH-1:0]    q_0;
wire [BITMAP_MEM_WIDTH-1:0]    q_1;
wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] addr_0;
reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] addr_1 =0;
wire wren_0;
wire wren_1;

//assign data_0 = dec_data;
//assign wren_0 = dec_valid;
//assign addr_0 = dec_addr;
//assign encr_data = q_0;

mem_dual #(.WIDTH(BITMAP_MEM_WIDTH), .DEPTH(MAX_BITMAP_MEM_DEPTH), .FILE("DUMMY_ENCRYPTED_DATA.mem")) 
MEMORY
(
    .clock(clock),
    .address_0(dec_addr),
    .address_1(addr_1),
    .data_0(dec_data),
    .data_1(data_1),
    .wren_0(dec_valid),
    .wren_1(0),
    .q_0(encr_data),
    .q_1(q_1)
);


initial
begin

    $dumpfile("dec_x_mem_tb.vcd");
    $dumpvars(0,dec_x_mem_tb);
    init <= 0;
    start <= 0;
    reset <= 1;
    bit_map_depth <= 0;
    #200
    
    reset <= 0;
    
//    @(posedge ready) // if ready was working you could wait for ready
    #10
        
    init <= 1;
    key <= 1; //{(128){1'b0}};

    $monitor(,$time, "init=%b,done_init=%b,start=%b,dec_data=%b,dec_valid=%b,ready=%b",init,done_init,start,dec_data,dec_valid,ready);
    
    #10 
    
    init <= 0;    
    
    // #10
    @(posedge done_init);
    
    init <= 0; // added init = 0 here because your done_init is received with in one clock cycle otherwise move "#10 init <= 0;" before  @(posedge done_init);
    
    //key scheduling completed, now start decryption
    #10
    
    start <= 1;
    bit_map_depth <= 4;

    #10 
   
    start <= 0;

   
   @(posedge done); // waiting for decryption to finish

   
    #100
    $finish;
    
end


always #5 clock = ~clock; 




endmodule