`include "clog2.v"

module controller
#(
    parameter IN_SIZE_WIDTH = 32,
    parameter BITMAP_MEM_WIDTH = 128,
    parameter MAX_BITMAP_MEM_DEPTH = 2048
)
(
    input wire                                      clock,
    input wire                                      reset,

    input wire                                      start_signal,
    
    input wire                                      init,
    
    input wire [BITMAP_MEM_WIDTH-1:0]                  in_bitmap,
    input wire                                      in_bitmap_valid,
    input wire [IN_SIZE_WIDTH-1:0]                  in_bitmap_size,
    
    output reg [BITMAP_MEM_WIDTH-1:0]               bitmap_width_adjusted,
    output reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]   bitmap_addr,
    output reg                                      bitmap_wr_en,                     

    output reg [`CLOG2(MAX_BITMAP_MEM_DEPTH)-1:0]   bit_map_depth,
    output reg                                      init_key,
    output reg                                      dec_enc_start, // CHECK
    input wire                                      done,  // CHECK
    input wire                                      done_init_key,
    output reg                                      ready,
    //input wire                                      dec_ready,
    output reg                                      done_signal,
    //////// Interface for the controller and Shake modules ////////
    output reg                                      din_valid,
    output reg [31:0]                               din,
    input wire                                      din_ready,
    input wire                                      dout_valid,
    input wire [31:0]                               dout,
    output reg                                      dout_ready,
    output reg [127:0]                              res,
    
    
    output reg                                      encrypt,
    output wire                                      ready_to_start_encr

    //output wire                                      start_decryption // If start_decryption == 1 decrypt, otherwise encrypt

);

reg ready_to_start_encryption; // 'True' if SHAKE has produced the output and we have reconstructed it.
reg start_shake = 0;

assign ready_to_start_encr = ready_to_start_encryption;

always@(posedge clock)
begin
    if (init) begin
        bitmap_width_adjusted <= 0;
    end
    else if (in_bitmap_valid) begin
        bitmap_width_adjusted <= in_bitmap;
    end
end

always@(posedge clock)
begin
    if (init) begin
        bitmap_wr_en <= 0;
    end
    else if (in_bitmap_valid) begin
            bitmap_wr_en <= 1;
    end
    else begin
        bitmap_wr_en <= 0;
    end
end

always@(posedge clock)
begin
    if (init) begin
        bitmap_addr <= 0;
    end
    else if (bitmap_wr_en) begin
        bitmap_addr <= bitmap_addr + 1;
    end
end

localparam [4:0]
    s_wait_init_key                 = 0,
    s_done_init_key                 = 1,
    s_start_dec                     = 2,
    s_done_dec                      = 3,
    s_start_shake                   = 4,
    s_done_shake                    = 5,
    s_start_enc                     = 6,
    s_done_enc                      = 7,
    s_done                          = 8,
    /// Rest of states are for triggering the SHAKE module
    output_length                   = 9,
    input_length                    = 10,
    data_0                          = 11,
    data_1                          = 12,
    data_2                          = 13,
    data_3                          = 14,
    read_0                          = 15,
    read_1                          = 16,
    read_2                          = 17,
    read_3                          = 18,
    stall_0                         = 19,
    stall_1                         = 20,
    stall_2                         = 21,
    stall_3                         = 22,
    done_trng                       = 23;

reg [4:0] state;
reg [4:0] state_next;
reg [4:0] state_next1;
reg [4:0] state1; // For the SHAKE module


always @(posedge clock)
begin

    state <= state_next;
    state1 <= state_next1;

end



always@(posedge clock)
begin
    if (reset) begin
        bit_map_depth <= 0;
    end
    else if (start_signal) begin
        bit_map_depth <= in_bitmap_size[IN_SIZE_WIDTH-1:`CLOG2(BITMAP_MEM_WIDTH)] + (in_bitmap_size[`CLOG2(BITMAP_MEM_WIDTH)-1:0] != 0);
    end
end

// FSM for interaction between Controller and Crypto (Decryption/Encryption) engine
always @(*)
    begin
    if (reset) begin
        state_next <= s_wait_init_key;
        dec_enc_start <= 0;
        ready <= 1;
        done_signal <= 0;
        init_key <= 0;
        start_shake <= 0;
        encrypt <= 0;
    end
    else begin
        case(state)
        s_wait_init_key: begin
                dec_enc_start <= 0;
                done_signal <= 0; 
                init_key <= 0;
                start_shake <= 0;
                encrypt <= 0;
                if (start_signal) begin // Simply start the whole thing here, if start_signal = 1. Guess this will happen only the very first time           
                        state_next <= s_done_init_key;
                        ready <= 0;
                        init_key <= 1;
                end
                else begin
                        state_next <= s_wait_init_key;
                        ready <= 1;
                        init_key <= 0;
                end
        end       
        
       s_done_init_key: begin
                done_signal <= 0;
                ready <= 0;
                init_key <= 0;
                dec_enc_start <= 0;
                start_shake <= 0;
                encrypt <= 0;
                if (done_init_key) begin
                        state_next <= s_start_dec;
                end
                else begin
                        state_next <= s_done_init_key;
                end
        end
        
        s_start_dec: begin
                done_signal <= 0;
                ready <= 0;
                init_key <= 0;
                dec_enc_start <= 1;
                start_shake <= 0;
                state_next <= s_done_dec;
                encrypt <= 0;
        end

        s_done_dec: begin
                dec_enc_start <= 0;
                encrypt <= 0;
                ready <= 0;
                init_key <= 0;
                start_shake <= 0;
                done_signal <= 0;
                if (done) begin
                       state_next <= s_start_shake;
//                         state_next <= s_done;
                end
                else begin
                        state_next <= s_done_dec;
                end
        end

        s_start_shake: begin
                dec_enc_start <= 0;
                done_signal <= 0;
                ready <= 0;
                init_key <= 0;
                start_shake <= 1;
                state_next <= s_done_shake;
                encrypt <= 0;
        end

        s_done_shake: begin
                dec_enc_start <= 0;
                done_signal <= 0;
                ready <= 0;
                init_key <= 0;
                start_shake <= 0;
                encrypt <= 0;
                if (ready_to_start_encryption) begin
                      state_next <= s_start_enc;
                        //  state_next <= s_done;
                end
                else begin
                        state_next <= s_done_shake;
                end
        end

        s_start_enc: begin
                done_signal <= 0;
                ready <= 0;
                init_key <= 0;
                dec_enc_start <= 1;
                start_shake <= 0;
                state_next <= s_done_enc;
                encrypt <= 1;
        end

        s_done_enc: begin
                dec_enc_start <= 0;
                done_signal <= 0;
                ready <= 0;
                init_key <= 0;
                start_shake <= 0;
                encrypt <= 1;
                if (done) begin
                        state_next <= s_done;
                end
                else begin
                        state_next <= s_done_enc;
                end
        end
        
        s_done: begin
                done_signal <= 1;
                dec_enc_start <= 0;
                ready <= 1;
                start_shake <= 0;
                init_key <= 0;
                state_next <= s_wait_init_key;
                encrypt <= 0;
        end
  
        default: begin
            state_next <= s_wait_init_key;
            done_signal <= 0;
            dec_enc_start <= 0;
            start_shake <= 0;
            ready <= 0; 
            init_key <= 0;
        end
        endcase
    end
end

 // Protocol to trigger the SHAKE module
always @(*)
    begin
    if (reset) begin
        din_valid <= 0;
        din <= 32'h00000000;
        ready_to_start_encryption <= 0;
        dout_ready <= 0;
        en_shift_hash <= 0;
    end
    else begin
        case(state1)
        output_length: begin   
            ready_to_start_encryption <= 0;
            en_shift_hash <= 0;
            if (start_shake) begin
                // res <= 0;
                if (din_ready) begin
                    din_valid <= 1;
                end
                else begin
                    din_valid <= 0;
                end
                din <= 32'h00000080; // 128-bits output legnth
                dout_ready <= 0;
                state_next1 <= input_length;
            end
            else begin
                din_valid <= 0;
                dout_ready <= 0;
                state_next1 <= output_length;
            end
        end

        input_length: begin
            if (din_ready) begin
                    din_valid <= 1;
                    state_next1 <= data_0;
            end
            else begin
                din_valid <= 0;
                state_next1 <=  input_length;
            end
            din <= 32'h80000080; // 128-bits input length
            dout_ready <= 0;
            ready_to_start_encryption <= 0;
            en_shift_hash <= 0;
            
        end

        data_0: begin
            if (din_ready) begin
                    din_valid <= 1;
                    state_next1 <= stall_0;
            end
            else begin
                din_valid <= 0;
                state_next1 <= data_0;
            end
            din <= 32'h12345678; // Random, hard-coded data message in 32-bits block
            dout_ready <= 0;
            ready_to_start_encryption <= 0;
            en_shift_hash <= 0;
            
        end

        stall_0: begin
           state_next1 <= data_1; 
           din_valid <= 0;
           dout_ready <= 0;
           ready_to_start_encryption <= 0;
           en_shift_hash <= 0;
        end
        
        data_1: begin
            if (din_ready) begin
                din_valid <= 1;
                state_next1 <= stall_1;
            end
            else begin
                state_next1 <= data_1;
                din_valid <= 0;
            end
            din <= 32'h87654321; // Random, hard-coded data message in 32-bits block
            dout_ready <= 0;
            ready_to_start_encryption <= 0;
            en_shift_hash <= 0;
            
        end
        
        stall_1: begin
           state_next1 <= data_2; 
           din_valid <= 0;
           dout_ready <= 0;
           ready_to_start_encryption <= 0;
           en_shift_hash <= 0;
        end

        data_2: begin
            if (din_ready) begin
                    din_valid <= 1;
                    state_next1 <= stall_2;
            end
            else begin
                din_valid <= 0;
                state_next1 <= data_2;
            end
            din <= 32'h11111111; // Random, hard-coded data message in 32-bits block
            dout_ready <= 0;
            ready_to_start_encryption <= 0;
            en_shift_hash <= 0;
            
        end
        
         stall_2: begin
           state_next1 <= data_3; 
           din_valid <= 0;
           dout_ready <= 0;
           ready_to_start_encryption <= 0;
           en_shift_hash <= 0;
        end

        data_3: begin
            if (din_ready) begin
                    din_valid <= 1;
                    state_next1 <= read_0;
            end
            else begin
                din_valid <= 0;
                state_next1 <= data_3;
            end
            din <= 32'h00000000; // Random, hard-coded data message in 32-bits block
            dout_ready <= 0;
            ready_to_start_encryption <= 0;
            en_shift_hash <= 0;
            
        end

        stall_3: begin
           state_next1 <= read_0; 
           din_valid <= 0;
           dout_ready <= 0;
           ready_to_start_encryption <= 0;
           en_shift_hash <= 0;
        end

        read_0: begin
            din_valid <= 0;
            ready_to_start_encryption <= 0;
            if (dout_valid) begin
                dout_ready <= 1;
                en_shift_hash <= 1;
                state_next1 <= read_1;
            end
            else begin
                dout_ready <= 0;
                state_next1 <= read_0;
                en_shift_hash <= 0;
            end
        end

        read_1: begin
            din_valid <= 0;
            ready_to_start_encryption <= 0;
            if (dout_valid) begin
                dout_ready <= 1;
                en_shift_hash <= 1;
                state_next1 <= read_2;
            end
            else begin
                dout_ready <= 0;
                state_next1 <= read_1;
                en_shift_hash <= 0;
            end
        end

        read_2: begin
            din_valid <= 0;
            ready_to_start_encryption <= 0;
            if (dout_valid) begin
                dout_ready <= 1;
                en_shift_hash <= 1;
                ready_to_start_encryption <= 0;
                state_next1 <= read_3;
            end
            else begin
                dout_ready <= 0;
                ready_to_start_encryption <= 0;
                state_next1 <= read_2;
                en_shift_hash <= 0;
            end
        end

        read_3: begin
            din_valid <= 0;
            if (dout_valid) begin
                dout_ready <= 1;
                en_shift_hash <= 1;
                ready_to_start_encryption <= 0;
                state_next1 <= done_trng;
            end
            else begin
                dout_ready <= 0;
                ready_to_start_encryption <= 0;
                state_next1 <= read_3;
                en_shift_hash <= 0;
            end
        end
        done_trng: begin
            din_valid <= 0;
            dout_ready <= 0;
            ready_to_start_encryption <= 1;
            state_next1 <= output_length;
            en_shift_hash <= 0;
        end

        default: begin
            din_valid <= 0;
            din <= 0;
            dout_ready <= 0;
            ready_to_start_encryption <= 0;
            state_next1 <= output_length;
            en_shift_hash <= 0;
        end

        endcase 
    end

end

reg en_shift_hash;
always@(posedge clock)
begin
    if (start_shake) begin
        res <= 0;
    end
    else if (en_shift_hash) begin
        res <= {res[95:0], dout[7:0], dout[15:8], dout[23:16], dout[31:24]};
    end
end

endmodule
