//`include "dummy_AES.v"
//`include "clog2.v"

module crypto_engine
#(
    parameter BITMAP_SIZE_BITS      = 512,
    parameter BITMAP_MEM_WIDTH      = 128,   
    parameter MAX_BITMAP_MEM_DEPTH      = (BITMAP_SIZE_BITS + (BITMAP_MEM_WIDTH-BITMAP_SIZE_BITS%BITMAP_MEM_WIDTH)%BITMAP_MEM_WIDTH)/BITMAP_MEM_WIDTH   // Needs to be decided
)
(
    input wire                                          clock,
    input wire                                          reset,
    input wire [BITMAP_MEM_WIDTH-1:0]                   din,
 
    output wire [BITMAP_MEM_WIDTH-1:0]                  dout, 
    output reg                                          dout_valid,
    output reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]         addr=0,
    
    input  [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]           bit_map_depth,
     
    output reg                                          eng_ready, 
    
    input wire                                          init,
    input wire                                          start,
    output reg                                          done,
    output wire                                         done_init,
    input wire [BITMAP_MEM_WIDTH-1:0]                   key,

    input wire                                          start_encr
);


reg start_aes = 0;


AES_EncDec
AES(
    .clk(clock),
    .rst(reset),
    .din(din),
    .key(key),
    .dout(dout),
    .decrypt(!start_encr ? 1'b1 : 1'b0),
    .init(init),
    .start(start_aes),
    .ready(ready), 
    .done(done_enc_dec),
    .done_init(done_init),
    .almost_done()
);

localparam [2:0] // 6 states required
    init1               = 3'b000,
    wait1               = 3'b001,
    wait_for_start      = 3'b010,
    dec_enc             = 3'b011,
    dec_enc_done        = 3'b100, 
    write               = 3'b101;

reg [2:0] state;
reg [2:0] state_next;


always @(posedge clock)
begin

    state <= state_next;

end

reg addr_en;
// wire done_enc_dec;
always@(posedge clock)
begin
    if (init) begin // Needs to be updated, or define a new offset for shake output for the memory block
        addr <= 0;
    end
    else if (addr_en) begin
        addr <= addr + 1;
    end
end

reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0] bit_map_depth_reg;

always@(posedge clock)
begin
   if (start) begin
       bit_map_depth_reg <= bit_map_depth;
   end
end

 always @(*)
    begin
    if (reset) begin
        state_next <= init1;
        dout_valid <= 0;
        start_aes <= 0;
        eng_ready <= 0;
        addr_en <= 0;
        done <= 0; 
    end
    else begin
        
        case(state)
        
        init1: begin 
            addr_en <= 0;
            start_aes <= 0;
            done <= 0; 
            eng_ready <= 0;
            if (init)
                begin
                    dout_valid <= 0;
                    state_next <= wait1;
                end
            else
                begin
                    dout_valid <= 0;
                    state_next <= init1;
                end
        end
        
        wait1: begin
            addr_en <= 0;
            start_aes <= 0;
            done <= 0; 
            eng_ready <= 0;
            if (done_init)
                begin
                    dout_valid <= 0;
                    state_next <= wait_for_start;
                end
            else
                begin
                    dout_valid <= 0;
                    state_next <= wait1;
                end
        end
        
        wait_for_start: begin
            dout_valid <= 0;
            start_aes <= 0;
            addr_en <= 0;
            done <= 0;
            if (init) begin
                state_next <= wait1;
                eng_ready <= 0;
            end
            else if (start || start_encr) begin // CHECK
                state_next <= dec_enc;
                eng_ready <= 0;
            end
            else begin
                state_next <= wait_for_start;
                eng_ready <= 1;
            end
        end
        
        dec_enc: begin
            addr_en <= 0;
            done <= 0; 
            eng_ready <= 0;
            if (ready) begin
                dout_valid <= 0;
                state_next <= dec_enc_done;
                start_aes <= 1;
            end
            else begin
                dout_valid <= 0;
                state_next <= dec_enc;
                start_aes <= 0;
            end
         end

        dec_enc_done: begin 
            start_aes <= 0;
            done <= 0; 
            eng_ready <= 0;
            if (done_enc_dec)begin
                dout_valid <= 1;
                if (addr == (bit_map_depth_reg)) begin // CHECK
                    addr_en <= 0;
                end
                else begin
                    addr_en <= 1;
                end
                state_next <= write;
            end
            else begin
                dout_valid <= 0;
                addr_en <= 0;
                state_next <= dec_enc_done;
            end
        end
             
        write: begin 
            dout_valid <= 0;
            eng_ready <= 0;
            addr_en <= 0;
            start_aes <= 0; 
           if ((addr == bit_map_depth_reg) || (addr == bit_map_depth_reg + 1)) begin // CHECK
               done <= 1; 
               state_next <= wait_for_start;
            end
            else begin
                done <= 0;
                state_next <= dec_enc;
            end
        end
        
        
        
        default: begin
            state_next <= init1;
            done <= 0;
            dout_valid <= 0;
            addr_en <= 0;
            start_aes <= 0;
            eng_ready <= 0;
        end
        endcase
    end
    end




endmodule
