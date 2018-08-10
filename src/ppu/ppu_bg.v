`timescale 1ns / 1ps

module ppu_bg
(
        input wire clk_in,
        input wire rst_in,
        input wire ri_bg_en,
        input wire ri_bg_clip,
        input wire [2:0] ri_fv,
        input wire [4:0] ri_vt,
        input wire ri_v,
        input wire [2:0] ri_fh,
        input wire [4:0] ri_ht,
        input wire ri_h,
        input wire ri_s,
        input wire [9:0] vga_nes_x,
        input wire [9:0] vga_nes_y,
        input wire [9:0] vga_nes_y_next,
        input wire vga_pix_pulse,
        input wire [7:0] vram_d_in,
        input wire ri_trans,
        input wire ri_inc_addr_in,
        input wire ri_inc_addr_amt_in,
        output reg [13:0] vram_a_out,
        output wire [3:0]  palette_idx_out
    );
    
    reg [ 2:0] q_fvc,           d_fvc;            // fine vertical scroll counter
    reg [ 4:0] q_vtc,           d_vtc;            // vertical tile index counter
    reg        q_vc,            d_vc;             // vertical name table selection counter
    reg [ 4:0] q_htc,           d_htc;            // horizontal tile index counter
    reg        q_hc,            d_hc;             // horizontal name table selection counter

    reg [ 7:0] q_par,           d_par;            // picture address register (holds tile index)
    reg [ 1:0] q_ar,            d_ar;             // tile attribute value latch (bits 3 and 2)
    reg [ 7:0] q_pd0,           d_pd0;            // palette data 0 (bit 0 for tile)
    reg [ 7:0] q_pd1,           d_pd1;            // palette data 1 (bit 1 for tile)

    reg [ 8:0] q_bg_bit3_shift, d_bg_bit3_shift;  // shift register with per-pixel bg palette idx bit 3
    reg [ 8:0] q_bg_bit2_shift, d_bg_bit2_shift;  // shift register with per-pixel bg palette idx bit 2
    reg [15:0] q_bg_bit1_shift, d_bg_bit1_shift;  // shift register with per-pixel bg palette idx bit 1
    reg [15:0] q_bg_bit0_shift, d_bg_bit0_shift;  // shift register with per-pixel bg palette idx bit 0
    
    always @(posedge clk_in)
      begin
        if (rst_in)
          begin
            q_fvc           <=  2'h0;
            q_vtc           <=  5'h00;
            q_vc            <=  1'h0;
            q_htc           <=  5'h00;
            q_hc            <=  1'h0;
            q_par           <=  8'h00;
            q_ar            <=  2'h0;
            q_pd0           <=  8'h00;
            q_pd1           <=  8'h00;
            q_bg_bit3_shift <=  9'h000;
            q_bg_bit2_shift <=  9'h000;
            q_bg_bit1_shift <= 16'h0000;
            q_bg_bit0_shift <= 16'h0000;
          end
        else
          begin
            q_fvc           <= d_fvc;
            q_vtc           <= d_vtc;
            q_vc            <= d_vc;
            q_htc           <= d_htc;
            q_hc            <= d_hc;
            q_par           <= d_par;
            q_ar            <= d_ar;
            q_pd0           <= d_pd0;
            q_pd1           <= d_pd1;
            q_bg_bit3_shift <= d_bg_bit3_shift;
            q_bg_bit2_shift <= d_bg_bit2_shift;
            q_bg_bit1_shift <= d_bg_bit1_shift;
            q_bg_bit0_shift <= d_bg_bit0_shift;
          end
      end
    
    //
    // Scroll counter management.
    //
    reg upd_v_cntrs;
    reg upd_h_cntrs;
    reg inc_v_cntrs;
    reg inc_h_cntrs;
    
    always @*
      begin;
        if (ri_inc_addr_in)
          begin
            if (ri_inc_addr_amt_in)
                begin
                    d_fvc = q_fvc + 3'h1;
                    d_vc  = q_vc + 1'h1;
                    d_hc  = q_hc + 1'h1;
                    d_vtc = q_vtc + 5'h1;
                end
            else
                 begin
                    d_fvc = q_fvc+3'h1;
                    d_vc  = q_vc+1'h1;
                    d_hc  = q_hc+1'h1;
                    d_vtc = q_vtc+5'h1;
                    d_htc = q_htc+5'h1;
                 end
          end
        else
          begin
            if (inc_v_cntrs)
              begin
                if ({ q_vtc, q_fvc } == { 5'b1_1101, 3'b111 })
                    begin
                         d_vc  = ~q_vc;
                         d_vtc =  5'h0;
                         d_fvc =  3'h0;
                    end
                else
                    begin
                        d_vc   = q_vc  + 1'h1;
                        d_vtc  = q_vtc + 5'h1;
                        d_fvc  = q_fvc + 3'h1;
                    end
              end
            if (inc_h_cntrs)
              begin
                d_hc  =  q_hc  + 1'h2;
                d_htc =  q_htc + 5'h2;
              end
          
            if (upd_v_cntrs || ri_trans)
              begin
                d_vc  = ri_v;
                d_vtc = ri_vt;
                d_fvc = ri_fv;
              end
    
            if (upd_h_cntrs || ri_trans)
              begin
                d_hc  = ri_h;
                d_htc = ri_ht;
              end
          end
      end
    
    
    //localparam [2:0] VRAM_A_SEL_RI       = 3'h0,
    //                 VRAM_A_SEL_NT_READ  = 3'h1,
    //                 VRAM_A_SEL_AT_READ  = 3'h2,
    //                 VRAM_A_SEL_PT0_READ = 3'h3,
    //                 VRAM_A_SEL_PT1_READ = 3'h4;
    
    reg [2:0] vram_a_sel;
    
    always @*
      begin
        case (vram_a_sel)
          3'h0:
            vram_a_out = { q_fvc[1:0], q_vc, q_hc, q_vtc, q_htc };
          3'h1:
            vram_a_out = { 2'b10, q_vc, q_hc, q_vtc, q_htc };
          3'h2:
            vram_a_out = { 2'b10, q_vc, q_hc, 4'b1111, q_vtc[4:2], q_htc[4:2] };
          3'h3:
            vram_a_out = { 1'b0, ri_s, q_par, 1'b0, q_fvc };
          3'h4:
            vram_a_out = { 1'b0, ri_s, q_par, 1'b1, q_fvc };

        endcase
      end
    

    wire clip;
    
    always @*
      begin
      
        d_par           = q_par;
        d_ar            = q_ar;
        d_pd0           = q_pd0;
        d_pd1           = q_pd1;
        d_bg_bit3_shift = q_bg_bit3_shift;
        d_bg_bit2_shift = q_bg_bit2_shift;
        d_bg_bit1_shift = q_bg_bit1_shift;
        d_bg_bit0_shift = q_bg_bit0_shift;

        upd_v_cntrs = 1'b0;
        inc_v_cntrs = 1'b0;
        upd_h_cntrs = 1'b0;
        inc_h_cntrs = 1'b0;
        
        if(ri_bg_en)
            begin
                if(vga_nes_y == 319)
                    begin
                        upd_h_cntrs = 1'b1; 
                    end
                else
                    if(vga_nes_y != vga_nes_y_next)
                        begin
                            if(vga_nes_y_next == 0)
                                begin
                                     upd_v_cntrs = 1'b1;
                                end
                            else
                                begin
                                     inc_v_cntrs = 1'b1;
                                end
                        end
                    if(vga_nes_x < 256 || (vga_nes_x >= 320 & vga_nes_x < 340) )
                        begin
                            d_bg_bit3_shift = { q_bg_bit3_shift[8], q_bg_bit3_shift[8:1] };
                            d_bg_bit2_shift = { q_bg_bit2_shift[8], q_bg_bit2_shift[8:1] };
                            d_bg_bit1_shift = { q_bg_bit1_shift[15], q_bg_bit1_shift[15:1] };
                            d_bg_bit0_shift = { q_bg_bit0_shift[15], q_bg_bit0_shift[15:1] };
                        end
                    case(vga_nes_x[2:0])
                        3'h7:
                            begin
                               d_bg_bit3_shift = { q_ar[1],7'h0 };
                               d_bg_bit2_shift = { q_ar[0],7'h0 };
                               d_bg_bit1_shift = { q_bg_bit1_shift[7], q_bg_bit1_shift[7:0] };
                               d_bg_bit0_shift = { q_bg_bit1_shift[7], q_bg_bit0_shift[7:0] };
                            end
                        3'b000:
                            begin
                               vram_a_sel = 3'h1;
                               d_par      = vram_d_in;
                            end
                         3'b001:
                            begin
                               vram_a_sel = 3'h2;
                               d_ar      = 1'b0;
                            end
                         3'b010:
                            begin
                                vram_a_sel = 3'h2;
                                d_pd0 = vram_d_in;
                            end
                          3'b011:
                            begin
                                vram_a_sel = 3'h3;
                                d_pd1 = vram_d_in;
                             end
                    endcase
            end
        
        
    
    end
    
    assign clip            = ri_bg_clip && (vga_nes_x >= 10'h000) && (vga_nes_x < 10'h008);
    assign palette_idx_out = (!clip && ri_bg_en) ? { q_bg_bit3_shift[ri_fh],q_bg_bit2_shift[ri_fh],q_bg_bit1_shift[ri_fh],q_bg_bit0_shift[ri_fh] } : 4'h0;
    

endmodule
