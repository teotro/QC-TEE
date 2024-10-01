// Top level wrapper


module top_with_fifo
#(
  parameter BITMAP_MEM_WIDTH        = 128,  // Same as decryption memory input width
  parameter MAX_BITMAP_MEM_DEPTH    = 2048, // Depends on max expected bitmap size
  parameter BITMAP_MEM_INIT         = 0,    // Initialize memory to 0s, if INIT is true

  parameter AES_KEY_SIZE            = 128,
  parameter AES_ROUNDS              = 10,

  parameter IN_BITMAP_WIDTH         = 128,
  parameter IN_SIZE_WIDTH           = 32,

  parameter OUT_DATA_WIDTH          = 128,
  parameter OUT_SIZE_WIDTH          = 32,
  parameter TRNG_SEED_WIDTH         = 128,
  parameter NUM_SWITCHES            = 7,
  
   parameter BITMAP_SIZE_BITS      = 512,
  parameter BITMAP_MEM_DEPTH      = (BITMAP_SIZE_BITS + (BITMAP_MEM_WIDTH-BITMAP_SIZE_BITS%BITMAP_MEM_WIDTH)%BITMAP_MEM_WIDTH)/BITMAP_MEM_WIDTH,   // Needs to be decided


  parameter DEPTH_OF_TRNG_MEM = (NUM_SWITCHES > TRNG_SEED_WIDTH)? (NUM_SWITCHES + (32-NUM_SWITCHES%32)%32)/32 : TRNG_SEED_WIDTH/32,

   parameter BITMAP_FILE             = ""
)
(
  // Clock and reset signals
  input    wire                                 clock,
  input    wire                                 reset,
  // Control signals input to the switch control module
  input    wire                                 sync,
  input    wire                                 init,

  input    wire                                 start_signal,
  output   reg                                  done_signal,
  // Signals for input AES key
  input    wire [AES_KEY_SIZE-1:0]                 in_key,

  
  // Signals for input bitmap
  input    wire [IN_BITMAP_WIDTH-1:0]              in_bitmap,

  input   wire                                    in_bitmap_valid,
  input   wire [IN_SIZE_WIDTH-1:0]                in_bitmap_size,
//   input   wire [IN_SIZE_WIDTH-1:0]                shake_addr,
  
// FIFO signals
  input wire i_rd,
  output wire fifo_empty,
  output wire [NUM_SWITCHES-1:0] output_switches,

  // Signals for output bitmap
  output wire [OUT_DATA_WIDTH-1:0]                            out_bitmap,
  input  wire                                                 bitmap_en,
  input  wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]              bitmap_addr1
);

// Switch control module <-> decryption engine signals
wire                    done;
wire                    start;


// Decryption engine <-> memory signals
wire [BITMAP_MEM_WIDTH-1:0]         din;
wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] addr;
wire [BITMAP_MEM_WIDTH-1:0]         dout;
wire                                dout_valid;

// Memory <-> switch control module signals
wire [BITMAP_MEM_WIDTH-1:0]         out_dec_data;


wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] bit_map_depth;
wire init_key;
wire done_init_key;
wire start_dec;
wire ready_to_start_encr;
wire eng_ready;
wire dec_enc_done;

wire encrypt;
crypto_engine #(.BITMAP_MEM_WIDTH(BITMAP_MEM_WIDTH), .MAX_BITMAP_MEM_DEPTH(MAX_BITMAP_MEM_DEPTH)) 
DECRYPTION_ENCRYPTION
(
    .clock(clock),
    .reset(reset),
    
    // Signals to/from memory
    .din(din),
    .dout(dout),
    .dout_valid(dout_valid),
    .addr(addr),
    
    // Signals to/from controller
    .bit_map_depth(in_bitmap_size[`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]),
    .eng_ready(eng_ready),
    .init(init_key),
    .start(start),
    .done(dec_enc_done),
    .done_init(done_init_key),
    .key(in_key),
    .start_encr(encrypt) 
);


wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]   bitmap_addr;
wire bitmap_wr_en;
wire ready;

// wires for SHAKE logic
wire            shake_din_valid;
wire [31:0]    shake_din;
wire            shake_din_ready;
wire            shake_dout_valid;
wire [31:0]    shake_dout;
wire            shake_dout_ready;
wire [127:0]    shake_res;
wire start_shifting_to_fifo;
// Switch control module
controller #(.IN_SIZE_WIDTH(IN_SIZE_WIDTH), .BITMAP_MEM_WIDTH(BITMAP_MEM_WIDTH), .MAX_BITMAP_MEM_DEPTH(MAX_BITMAP_MEM_DEPTH)) MAIN_CONTROL(
  .clock (clock),
  .reset (reset),

  .init(init),
  .in_bitmap(in_bitmap),
  .in_bitmap_valid(in_bitmap_valid),
  .in_bitmap_size(in_bitmap_size),
  
  .bitmap_width_adjusted(out_dec_data),
  .bitmap_addr(bitmap_addr),
  .bitmap_wr_en(bitmap_wr_en), // CHECK bit_map_wr_en or ready_to_start_encr signal
  
  .start_signal (start_signal),
  .done_signal (start_shifting_to_fifo),
  
  // Signals to/from decryption engine
  .done (dec_enc_done),
  .dec_enc_start (start),
  .ready(ready),
  .init_key(init_key),
  .done_init_key(done_init_key),
  .bit_map_depth(bit_map_depth),
  .ready_to_start_encr(ready_to_start_encr),
  .encrypt(encrypt),
  
  // Signals to/from SHAKE module
    .din_valid(shake_din_valid),
    .din(shake_din),
    .din_ready(shake_din_ready),
    .dout_valid(shake_dout_valid),
    .dout(shake_dout),
    .dout_ready(shake_dout_ready),
    .res(shake_res)
);

keccak_top SHAKE(
    .clk(clock),
    .rst(reset),
    .din_valid(shake_din_valid),
    .din_ready(shake_din_ready),
    .din(shake_din),
    .dout_valid(shake_dout_valid),
    .dout_ready(shake_dout_ready),
    .dout(shake_dout)
);

  
// Bitmap memory
mem_dual #(.WIDTH(BITMAP_MEM_WIDTH), .DEPTH(MAX_BITMAP_MEM_DEPTH), .FILE(BITMAP_FILE)) 
MEMORY
(
    .clock(clock),
    // Signals to/from decryption engine
    .data_0(bitmap_wr_en? out_dec_data: dout),
    .address_0(bitmap_wr_en? bitmap_addr:addr),
    .wren_0(bitmap_wr_en? bitmap_wr_en:dout_valid),
    .q_0(din),
    
    // Signals to/from controller module
    .data_1(shake_res),
    .address_1(enable_sifter? shift_addr: bitmap_en ? bitmap_addr1 : in_bitmap_size),
    .wren_1(ready_to_start_encr),
    .q_1(out_bitmap)
);

wire [NUM_SWITCHES-1:0] short_vector_out;
wire short_vector_out_valid;
wire fifo_full;
wire fifo_empty;

fifo #(
    .BW(NUM_SWITCHES),
    .LGFLEN(8)
) fifo_mod (
    .i_clk(clock),
    .i_wr(short_vector_out_valid), 
    .i_data(short_vector_out), // Shifter Writes to FIFO
    .o_full(fifo_full),
    .i_rd(i_rd),
    .o_empty(fifo_empty),
    .o_data(output_switches), // Read from FIFO to RF switches
    .o_fill()
);

shifter #( // The outputs of this module go to the FIFO as inputs
    .IN_WIDTH(OUT_DATA_WIDTH),
    .OUT_WIDTH(NUM_SWITCHES)
) shifter (
    .clock(clock),
    .reset(reset),
    .start(start_shifter),
    .fifo_full(fifo_full),
    .long_vector_in(out_bitmap),
    .short_vector_out(short_vector_out),
    .short_vector_out_valid(short_vector_out_valid),
    .done(done_shifter)
);

reg start_shifter;
wire done_shifter;

parameter S_WAIT_START = 0;
parameter S_CHECK_ADDR = 1;
parameter S_SHIFT = 2;


reg [2:0] state;
reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]  shift_addr;
reg enable_sifter;

always@(posedge clock) 
begin
  if (reset) begin
    state <= S_WAIT_START;
    done_signal <= 0;
    shift_addr <= 0;
  end

  else begin
    if (state == S_WAIT_START) begin 
      shift_addr <= 0;
      if (start_shifting_to_fifo) begin
        state <= S_CHECK_ADDR;
        enable_sifter <= 1;
      end
      else begin
        state <= S_WAIT_START;
        enable_sifter <= 0;
      end
    end

    else if (state == S_CHECK_ADDR) begin
      if (shift_addr == 4) begin
        done_signal <= 1;  
        state <= S_WAIT_START;
        enable_sifter <= 0;
      end
      else begin
        done_signal <= 0;
        state <= S_SHIFT;
      end
    end
    
    else if (state == S_SHIFT) begin
      if (done_shifter) begin
        state <= S_CHECK_ADDR;
        shift_addr <= shift_addr + 1;
      end
    end
  end
end

always@(*)
begin
  case(state)

    S_WAIT_START: begin
      start_shifter = 0;
    end
    
    S_CHECK_ADDR: begin
      if (shift_addr < 4) begin
        start_shifter = 1;
      end
      else begin
        start_shifter = 0;
      end
    end
    
    S_SHIFT: begin
      start_shifter = 0;
    end

    default: begin
      start_shifter = 0;
    end

  endcase
end

endmodule
