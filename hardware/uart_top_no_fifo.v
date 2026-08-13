
module uart_top_no_fifo #(
    parameter BAUD_RATE     = 115_200,
    parameter CLK_SPEED     = 100_000_000,

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
  

    parameter DEPTH_OF_TRNG_MEM = (NUM_SWITCHES > TRNG_SEED_WIDTH)? (NUM_SWITCHES + (32-NUM_SWITCHES%32)%32)/32 : TRNG_SEED_WIDTH/32,

    parameter BITMAP_FILE             = ""
) (
    input  wire clk_p,
    input  wire uart_rx,
    output wire uart_tx,
    output wire [6:0] output_switches_wire,
    output wire flag1,
    output wire flag2,
    output wire flag3
);

// Some boards don't have reset signal, tie reset to 0
reg            rst;

// Global clock
wire           clk;

// UART connections
reg  [7:0]     tx_byte;
wire [7:0]     rx_byte;
wire           tx_ready;
reg            tx_valid;
wire           rx_valid;
wire           tx_busy;

reg key_valid ;
reg bitmap_valid;
reg start_signal;
reg flag;
reg flag_debug;
reg flag_debug3;
wire done_signal;

reg                                   bitmap_en;
reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] bitmap_addr;

wire [OUT_DATA_WIDTH-1:0]   out_bitmap1;
reg [OUT_DATA_WIDTH-1:0]   out_bitmap ;

assign flag1 = flag;
assign flag2 = flag_debug;
assign flag3 = flag_debug3;


// UART configuration, see rxuart.v and txuart.v
// 8 bit words, one stop bit | parity exists, not fixed, odd | clocks per baud
localparam [30:0] INITIAL_SETUP = (4'b0000 << 27) | (3'b101 << 24) | (CLK_SPEED/BAUD_RATE);
localparam [2:0] depth = 4;

// localparam BW=128;
localparam LGFLEN=8;

 BUFG BUFG_inst (
    .O(clk), // 1-bit output: Clock output.
    .I(clk_p)  // 1-bit input: Clock input.
 );

// State machine parameters
localparam [4:0] 
                 RECONSTRUCT_KEY                = 0,
                 DONE_KEY                       = 1,
                 RECEIVE_BITMAP                 = 2,
                 DONE_BITMAP                    = 3,
                 IDLE                           = 4,
                 ENABLE_BITMAP                  = 5,
                 LOAD_BITMAP                    = 6,
                 DO_SHIFTING                    = 7,
                 CHECK_IF_DECRYPTION_IS_DONE    = 8,
                 GET_ENCR_SHAKE                 = 9,
                 DUMMY                          = 10,
                 STALL_STATE                    = 11,
                 STALL                          = 12,
                 STALL2                         = 13,
                 DUMMY2                         = 14,
                 STALL_STATE2                   = 15,
                 GET_BLOCK_SIZE                 = 16,
                 STALL_AFTER_BLOCK_SIZE         = 17,
                 STATE_1                        = 18,
                 STATE_2                        = 19,
                 STATE_3                        = 20,
                 STATE_4                        = 21,
                 READ                           = 22,
                 DONE                           = 23;

// Define register holding the state
reg [4:0] state = GET_BLOCK_SIZE;
reg [4:0] state_fifo = STATE_1;
reg [4:0] state_read_fifo = READ;

// Count how many 8-bits message you have sent
reg [4:0] counter = 0;

// Count how many 128-bits elements (from bitmap) you have received to meet the 'depth' parameter
reg [3:0] counter_depth = 0;

// Registers which holds the reconstructed 128-bits key
reg [127:0] aes_key ;
reg [127:0] aes_key_full ;

reg [127:0] bitmap ;
reg [127:0] bitmap_full ;

reg [7:0]   block_size;


always @(posedge clk) begin
    if (rst) begin
        tx_valid <= 0;
        tx_byte <= 0;
        counter <= 0;
        counter_depth <= 0;
        bitmap_addr <= 0;
        bitmap_en <= 1;
        key_valid <= 0;
        state <= GET_BLOCK_SIZE;
    end
    else begin
        case(state) 

        GET_BLOCK_SIZE: begin
            flag <= 0;
            bitmap_addr <= 0;
            counter <= 0;
            key_valid <= 0;
            if (rx_valid & !tx_busy) begin
                tx_valid <= 1;
                tx_byte <= rx_byte;
                block_size <= rx_byte;
                bitmap_en <= 0;
                state <= STALL_AFTER_BLOCK_SIZE;
            end
            else begin
                tx_valid <= 0;
                tx_byte <= 0;
                key_valid <= 0;
                block_size <= 0;
                bitmap_en <= 0;
                state <= GET_BLOCK_SIZE;
            end
        end

        STALL_AFTER_BLOCK_SIZE: begin
            flag <= 0;
            bitmap_addr <= 0;
            counter <= 0;
            key_valid <= 0;
            tx_valid <= 0;
            tx_byte <= 0;
            bitmap_en <= 0;
            state <= RECONSTRUCT_KEY;
        end     

        RECONSTRUCT_KEY: begin
            bitmap_en <= 1;
            bitmap_addr <= 0;
            if (rx_valid & !tx_busy) begin
                if (counter < 15) begin
                    flag <= 0;
                    aes_key[127:0] <= {aes_key[119:0],rx_byte};
                    tx_valid <= 1;
                    tx_byte <= rx_byte;
                    key_valid <= 0;
                    counter <= counter + 1;
                    state <= RECONSTRUCT_KEY;
                end
                else if (counter == 15) begin
                    flag <= 0;
                    aes_key[127:0] <= {aes_key[119:0],rx_byte};
                    tx_valid <= 1;
                    tx_byte <= rx_byte;
                    key_valid <= 0;
                    counter <= counter + 1;
                    state <= DONE_KEY;
                end
                else begin
                    flag <= 0;
                    tx_valid <= 0;
                    tx_byte <= 0;
                    key_valid <= 0;
                    state <= RECONSTRUCT_KEY;
                end
            end
            else begin
                tx_valid <= 0;
                tx_byte <= 0;
                key_valid <= 0;
                state <= RECONSTRUCT_KEY;
            end
        end

        DONE_KEY: begin
            flag <= 0;
            tx_valid <= 0;
            tx_byte <= 0;
            counter <= 0;
            bitmap_en <= 1;
            key_valid <= 1;
            bitmap_addr <= 0;
            aes_key_full <= aes_key;
            state <= RECEIVE_BITMAP;
        end

        RECEIVE_BITMAP: begin
            key_valid <= 0;
            bitmap_en <= 1;
            bitmap_addr <= 0;
            flag <= 0;
            if (rx_valid & !tx_busy) begin
                if (counter < 15) begin
                    bitmap[127:0] <= {bitmap[119:0],rx_byte};
                    tx_valid <= 1;
                    tx_byte <= rx_byte;
                    counter <= counter + 1;
                    state <= RECEIVE_BITMAP;
                end
                else if (counter == 15) begin
                    bitmap[127:0] <= {bitmap[119:0],rx_byte};
                    tx_valid <= 1;
                    tx_byte <= rx_byte;
                    counter_depth <= counter_depth + 1;
                    counter <= counter + 1;
                    state <= DONE_BITMAP;
                    end
                else begin
                    tx_valid <= 0;
                    tx_byte <= 0;
                    bitmap_valid <= 0;
                    state <= RECEIVE_BITMAP;
                end
            end
            else begin
                tx_valid <= 0;
                tx_byte <= 0;
                bitmap_valid <= 0;
                state <= RECEIVE_BITMAP;
            end
        end

        DONE_BITMAP: begin
            tx_valid <= 0;
            tx_byte <= 0;
            bitmap_en <= 1;
            bitmap_addr <= 0;
            flag <= 0;
                if (!tx_busy) begin
                counter <= 0;
                key_valid <= 0;
                bitmap_valid <= 1;
                bitmap_full <= bitmap;
                    if (counter_depth == block_size) begin
                    // if (counter_depth == depth) begin
                        counter_depth <= 0;
                        start_signal <= 1;
                        state <= IDLE;
                    end
                    else begin
                        state <= RECEIVE_BITMAP;
                    end
                end
                else begin
                    counter <= 0;
                    key_valid <= 0;
                    bitmap_valid <= 0;
                    state <= DONE_BITMAP;
                end   
            end

        IDLE: begin
            start_signal <= 0;
            bitmap_valid <= 0;
            key_valid <= 0;
            bitmap_en <= 0;
            bitmap_addr <= 0;
            if (done_signal) begin
                counter <= 0;
                tx_valid <= 0;
                tx_byte <= 0;
                counter_depth <= 0;
                flag <= 0;
                state <= ENABLE_BITMAP;
            end
            else begin
                tx_valid <= 0;
                tx_byte <= 0;
                flag <= 0;
                state <= IDLE;
            end
        end

        ENABLE_BITMAP: begin
            flag <= 0;
            bitmap_en <= 1;
            bitmap_addr <= 0;
            tx_byte <= 0;
            tx_valid <= 0;
            state <= STALL;
        end

        STALL: begin
            flag <= 0;
            tx_byte <= 0;
            tx_valid <= 0;
            bitmap_en <= 1;
            bitmap_addr <= 0;
            state <= LOAD_BITMAP;
        end

        LOAD_BITMAP: begin
            // if (bitmap_addr < 4) begin
            flag <= 0;
            out_bitmap <= out_bitmap1;
            // end
            // else begin
            //     out_bitmap <= 128'hf46e00bd246e207de04435ef765c995a;
            // end
            bitmap_en <= 1;
            tx_byte <= 0;
            tx_valid <= 0;
            // bitmap_addr <= 0;
            state <= DO_SHIFTING;
        end

        STALL2: begin
            flag <= 0;
            tx_byte <= 0;
            tx_valid <= 0;
            bitmap_en <= 1;
            // bitmap_addr <= 0;
            state <= DO_SHIFTING;
        end

        DO_SHIFTING: begin
            bitmap_en <= 1;
            flag <= 0;
        if (!tx_busy) begin
            if (counter < 15) begin
                tx_valid <= 1;
                tx_byte <= out_bitmap[7:0];
                out_bitmap <= {8'b00000000, out_bitmap[127:8]};
                counter <= counter + 1;
                state <= STALL_STATE;
            end
            else if (counter == 15) begin
                tx_valid <= 1;
                // bitmap_addr <= bitmap_addr + 1;
                tx_byte <= out_bitmap[7:0];
                out_bitmap <= {8'b00000000, out_bitmap[127:8]};
                counter <= counter + 1;
                counter_depth <=  counter_depth + 1;
                state <= STALL_STATE;
            end
            else begin
                tx_valid <=0;
                tx_byte <= 0;
                bitmap_en <= 1;
                state <= DO_SHIFTING;
            end
        end
        else begin
            tx_valid <= 0;
            tx_byte <= 0;
            state <= DO_SHIFTING;
        end
        end

        STALL_STATE: begin
            flag <= 0;
            if (counter == 16) begin
                bitmap_addr <= bitmap_addr + 1;
                counter <= 0;
                tx_valid <= 0;
                tx_byte <= 0;
                bitmap_en <=1;
                state <= CHECK_IF_DECRYPTION_IS_DONE;
            end
            else begin
                tx_byte <= 0;
                tx_valid <= 0;
                bitmap_en <=1;
                state <= DO_SHIFTING;
            end
        end

        CHECK_IF_DECRYPTION_IS_DONE: begin
            // bitmap_en <= 1;
            flag <= 0;
            if (counter_depth == block_size+1) begin
            // if (counter_depth == depth+1) begin
                if (!tx_busy) begin
                    tx_valid <= 0;
                    flag <= 0;
                    tx_byte <= 0;
                    bitmap_en <= 0;
                    counter_depth <= 0;
                    // state <= DUMMY;
                    // state <= GET_ENCR_SHAKE;
                    state <= DUMMY2;
                end
                else begin
                    tx_valid <= 0;
                    tx_byte <= 0;
                    flag <= 0;
                    bitmap_en <= 1;
                    state <= CHECK_IF_DECRYPTION_IS_DONE;
                end
            end
            else begin
                tx_byte <= 0;
                tx_valid <= 0;
                bitmap_en <= 1;
                // state <= DO_SHIFTING;
                state <= LOAD_BITMAP;
            end
        end 

        DUMMY2: begin
            tx_byte <= 0;
            tx_valid <=0;
            bitmap_en <= 0;
            flag <= 1;
            counter_depth <= 0;
            state <= RECONSTRUCT_KEY;
        end

        default: begin
            flag <= 0;
            tx_valid <= 0;
            tx_byte <= 0;
            state <= RECONSTRUCT_KEY;
        end

        endcase
    end
end


reg                         start_shifter;
wire                        fifo_full;
wire                         fifo_empty;
reg                         i_wr;
reg [NUM_SWITCHES-1:0]      i_data;
reg                         i_rd;
// reg [NUM_SWITCHES-1:0]      o_data;

wire                        short_vector_out_valid;
wire [NUM_SWITCHES-1:0]     short_vector_out;

reg [OUT_DATA_WIDTH-1:0]    output_for_shifter;
wire                        done_shift;
reg                         bitmap_en_shifter;

reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] bitmap_addr_shifter;

wire [8:0] total_chunks_of_seven; // FIXME

assign total_chunks_of_seven = block_size*(128/NUM_SWITCHES);

reg [7:0] tx_byte_shift;
reg       tx_valid_shift;


reg [8:0] counter_fifo = 0;

always @(posedge clk) begin
    if (rst) begin
        i_rd <= 0;
        counter_fifo <= 0;
        tx_byte_shift <= 0;
        tx_valid_shift <= 0;
        // flag_debug3 <= 0;
        state_read_fifo <= READ;
    end
    else begin
        case(state_read_fifo)

        READ: begin
        // flag_debug3 <= fifo_empty;
        if (!fifo_empty) begin
            // flag_debug3 <= 1; PASSED
            if (counter_fifo == total_chunks_of_seven) begin
                // flag_debug3 <= 1; PASSED
                if (!tx_busy) begin
                    tx_valid_shift <= 1;
                    tx_byte_shift <= {output_switches_wire, 1'b1};
                    // tx_byte_shift <= 8'hff;
                    counter_fifo <= counter_fifo + 1;
                    i_rd <= 1;
                    state_read_fifo <= DONE;
                end
                else begin
                    tx_valid_shift <= 0;
                    tx_byte_shift <= 0;
                    i_rd <= 0;
                    state_read_fifo <= READ;
                end
             end
            else begin
                if (!tx_busy) begin
                    counter_fifo <= counter_fifo + 1;
                    i_rd <= 1;
                    tx_valid_shift <= 1;
                    tx_byte_shift <= {output_switches_wire, 1'b1};
                    // tx_byte_shift <= 8'hff;
                    state_read_fifo <= READ;
                end
                else begin
                    i_rd <= 0;
                    tx_valid_shift <= 0;
                    tx_byte_shift <= 0;
                    state_read_fifo <= READ;
                end
            end
        end
        else begin
            i_rd <= 0;
            tx_valid_shift <= 0;
            tx_byte_shift <= 0;
            state_read_fifo <= READ;
        end
        end

        DONE: begin
            i_rd <= 0;
            tx_byte_shift <= 0;
            tx_valid_shift <= 0;
            state_read_fifo <= DONE;
        end

        default: begin
            counter_fifo <= 0;
            tx_byte_shift <= 0;
            tx_valid_shift <= 0;
            i_rd <= 0;
            // flag_debug3 <= 0;
            state_read_fifo <= READ;
        end


        endcase
    end

end

wire                                    sync;
wire                                    bitmap_en_mux;
wire [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] bitmap_addr_mux;

assign bitmap_addr_mux = flag ? bitmap_addr_shifter : bitmap_addr;
assign bitmap_en_mux = flag ? bitmap_en_shifter : bitmap_en;

// Incorporate the old top-module here
    top_with_fifo #(.BITMAP_MEM_WIDTH(BITMAP_MEM_WIDTH), .MAX_BITMAP_MEM_DEPTH(MAX_BITMAP_MEM_DEPTH), .BITMAP_MEM_INIT(BITMAP_MEM_INIT), .AES_KEY_SIZE(AES_KEY_SIZE), .AES_ROUNDS(AES_ROUNDS), .IN_BITMAP_WIDTH(IN_BITMAP_WIDTH), .IN_SIZE_WIDTH(IN_SIZE_WIDTH), .OUT_DATA_WIDTH(OUT_DATA_WIDTH), .OUT_SIZE_WIDTH(OUT_SIZE_WIDTH), .TRNG_SEED_WIDTH(TRNG_SEED_WIDTH), .NUM_SWITCHES(NUM_SWITCHES), .DEPTH_OF_TRNG_MEM(DEPTH_OF_TRNG_MEM), .BITMAP_FILE(BITMAP_FILE)
    ) top_with_fifo_inst
    (
        .clock(clk),
        .reset(rst),
        .sync(0),
        .init(key_valid),
        .start_signal(start_signal), // Provided by UART, when both key and bitmap have been full reconstructed
        .done_signal(done_signal),  
        .in_key(aes_key_full),
        // .in_key(128'h00000000000000000000000000000000),
        .in_bitmap(bitmap_full),
        .in_bitmap_valid(bitmap_valid),
        .in_bitmap_size(block_size),
        .out_bitmap(out_bitmap1),
        .bitmap_en(bitmap_en_mux),
        .bitmap_addr1(bitmap_addr_mux),
        .i_rd(i_rd),
        .fifo_empty(fifo_empty),
        .output_switches(output_switches_wire)
    );


// UART modules for TX and RX
txuart #(
    .INITIAL_SETUP(INITIAL_SETUP)
) tx_uart (
    .i_setup(INITIAL_SETUP),
    .i_clk(clk),
    .i_reset(rst),
    .i_wr(flag ? tx_valid_shift : tx_valid),
    .i_data(flag ? tx_byte_shift : tx_byte),
    // .i_wr(flag ? 1'b1 : tx_valid),
    // .i_data(flag ? 8'hff : tx_byte),
    .i_break(),
    .i_cts_n(),
    .o_uart_tx(uart_tx),
    .o_busy(tx_busy)
);

rxuart #(
    .INITIAL_SETUP(INITIAL_SETUP)
) rx_uart (
    .i_setup(INITIAL_SETUP),
    .i_clk(clk),
    .i_reset(rst),
    .i_uart_rx(uart_rx),
    .o_wr(rx_valid),
    .o_data(rx_byte),
    .o_break(),
    .o_parity_err(),
    .o_frame_err(),
    .o_ck_uart()
);


always@(posedge clk)
begin
    if (start_shifter) begin
        flag_debug3 <= 0;
    end
    else if (flag && done_shift) begin
        flag_debug3 <= 1;
    end
end

endmodule
