`timescale 1ns / 1ps


module ppu_ri
(
    input wire clk_in,
    input wire rst_in,
    input wire [2:0] select_in,
    input wire enable_in,     
    input wire rw_select_in,
    input wire [7:0] cpu_data_in,                  
    input wire [13:0] vram_add_out,
    input  wire [7:0] ri_vram_d_in,
    input  wire [7:0] ri_pram_d_in,
    input wire  vblank_in,
    input  wire  [7:0] ri_spr_ram_in,
    input wire ri_spr_of,
    input wire ri_spr_0_ex,
    
    output wire [7:0] cpu_data_out,
    output reg [7:0] ri_vram_dout,
    output reg ri_vram_wr,
    output reg ri_pram_wr,
    
    output wire [2:0] ri_fv,
    output wire [4:0] ri_vt,
    output wire ri_v,
    output wire [2:0] ri_fh,
    output wire [4:0] ri_ht,
    output wire ri_h,
    output wire ri_s,
    
    output reg ri_inc_addr,
    output wire ri_inc_addr_amt,
    output wire ri_nmi_en,
    output wire vblank_out,
    output wire ri_spr_en,
    output wire ri_bg_en,
    output wire ri_spr_clip,
    output wire ri_bg_clip,
    output wire ri_spr_h,
    output wire ri_pattern_sel,
    output wire ri_trans,
    output reg ri_spr_ram_wr,
    output wire [7:0]  ri_spr_ram_aout,
    output reg [7:0] ri_spr_ram_dout

    );
    
    
    
    
    reg [2:0] q_fv,  d_fv;   // fine vertical scroll latch
    reg [4:0] q_vt,  d_vt;   // vertical tile index latch
    reg       q_v,   d_v;    // vertical name table selection latch
    reg [2:0] q_fh,  d_fh;   // fine horizontal scroll latch
    reg [4:0] q_ht,  d_ht;   // horizontal tile index latch
    reg       q_h,   d_h;    // horizontal name table selection latch
    reg       q_s,   d_s;    // playfield pattern table selection latch
    
    
    reg [7:0] q_cpu_d_out,     d_cpu_d_out;      // output data bus latch for 0x2007 reads
    reg       q_upd_cntrs_out, d_upd_cntrs_out;  // output latch for upd_cntrs_out
    

    reg q_nmi_en,      d_nmi_en;      // 0x2000[7]: enables an NMI interrupt on vblank
    reg q_spr_h,       d_spr_h;       // 0x2000[5]: select 8/16 scanline high sprites
    reg q_spr_pt_sel,  d_spr_pt_sel;  // 0x2000[3]: sprite pattern table select
    reg q_addr_incr,   d_addr_incr;   // 0x2000[2]: amount to increment addr on 0x2007 access.
                                      //            0: 1 byte, 1: 32 bytes.
    reg q_spr_en,      d_spr_en;      // 0x2001[4]: enables sprite rendering
    reg q_bg_en,       d_bg_en;       // 0x2001[3]: enables background rendering
    reg q_spr_ls_clip, d_spr_ls_clip; // 0x2001[2]: left side screen column (8 pixel) object clipping
    reg q_bg_ls_clip,  d_bg_ls_clip;  // 0x2001[1]: left side screen column (8 pixel) bg clipping
    reg q_vblank,      d_vblank;      // 0x2002[7]: indicates a vblank is occurring
    
    
    reg       q_byte_sel,  d_byte_sel;   // tracks if next 0x2005/0x2006 write is high or low byte
    reg [7:0] q_rd_buf,    d_rd_buf;     // internal latch for buffered 0x2007 reads
    reg       q_rd_rdy,    d_rd_rdy;     // controls q_rd_buf updates
    reg [7:0] q_spr_ram_a, d_spr_ram_a;  // sprite ram pointer (set on 0x2003 write)
    
    reg       q_enable_in;               // last ncs signal (to detect falling edges)
    reg       q_vblank_in;               // last vblank_in signal (to detect falling edges)
    
    
    
    always @(posedge clk_in)
      begin
        if (rst_in)
            begin
                    q_fv            <= 2'h0;
                    q_vt            <= 5'h00;
                    q_v             <= 1'h0;
                    q_fh            <= 3'h0;
                    q_ht            <= 5'h00;
                    q_h             <= 1'h0;
                    q_s             <= 1'h0;
                    q_cpu_d_out     <= 8'h00;
                    q_upd_cntrs_out <= 1'h0;
                    q_nmi_en       <= 1'h0;
                    q_spr_h         <= 1'h0;
                    q_spr_pt_sel    <= 1'h0;
                    q_addr_incr     <= 1'h0;
                    q_spr_en        <= 1'h0;
                    q_bg_en         <= 1'h0;
                    q_spr_ls_clip   <= 1'h0;
                    q_bg_ls_clip    <= 1'h0;
                    q_vblank        <= 1'h0;
                    q_byte_sel      <= 1'h0;
                    q_rd_buf        <= 8'h00;
                    q_rd_rdy        <= 1'h0;
                    q_spr_ram_a     <= 8'h00;
                    q_enable_in        <= 1'h1;
                    q_vblank_in     <= 1'h0;
                  end
                else
                  begin
                    q_fv            <= d_fv;
                    q_vt            <= d_vt;
                    q_v             <= d_v;
                    q_fh            <= d_fh;
                    q_ht            <= d_ht;
                    q_h             <= d_h;
                    q_s             <= d_s;
                    q_cpu_d_out     <= d_cpu_d_out;
                    q_upd_cntrs_out <= d_upd_cntrs_out;
                    q_nmi_en       <= d_nmi_en;
                    q_spr_h         <= d_spr_h;
                    q_spr_pt_sel    <= d_spr_pt_sel;
                    q_addr_incr     <= d_addr_incr;
                    q_spr_en        <= d_spr_en;
                    q_bg_en         <= d_bg_en;
                    q_spr_ls_clip   <= d_spr_ls_clip;
                    q_bg_ls_clip    <= d_bg_ls_clip;
                    q_vblank        <= d_vblank;
                    q_byte_sel      <= d_byte_sel;
                    q_rd_buf        <= d_rd_buf;
                    q_rd_rdy        <= d_rd_rdy;
                    q_spr_ram_a     <= d_spr_ram_a;
                    q_enable_in        <= enable_in;
                    q_vblank_in     <= vblank_out;
                    end
      end
      
    always @*
        begin
          // Default most state to its original value.
          d_fv          = q_fv;
          d_vt          = q_vt;
          d_v           = q_v;
          d_fh          = q_fh;
          d_ht          = q_ht;
          d_h           = q_h;
          d_s           = q_s;
          d_cpu_d_out   = q_cpu_d_out;
          d_nmi_en     = q_nmi_en;
          d_spr_h       = q_spr_h;
          d_spr_pt_sel  = q_spr_pt_sel;
          d_addr_incr   = q_addr_incr;
          d_spr_en      = q_spr_en;
          d_bg_en       = q_bg_en;
          d_spr_ls_clip = q_spr_ls_clip;
          d_bg_ls_clip  = q_bg_ls_clip;
          d_byte_sel    = q_byte_sel;
          d_spr_ram_a   = q_spr_ram_a;
      
          d_rd_buf = (q_rd_rdy) ? ri_vram_d_in : q_rd_buf;
          d_rd_rdy = 1'b0;
      
          d_upd_cntrs_out = 1'b0;
      

          d_vblank = (vblank_in) ? 1'b1 :
                     (~q_vblank) ? 1'b0 : 1'b0; 

          ri_vram_wr = 1'b0;
          ri_vram_dout  = 8'h00;
          ri_pram_wr = 1'b0;
      
          ri_inc_addr = 1'b0;
      
          ri_spr_ram_dout  = 8'h00;
          ri_spr_ram_wr = 1'b0;
      
          // Only evaluate RI reads/writes on /CS falling edges.  This prevents executing the same
          // command multiple times because the CPU runs at a slower clock rate than the PPU.
          if (q_enable_in & ~enable_in)
            begin
              case (select_in)
                3'h0:
                     begin
                           d_nmi_en    = cpu_data_in[7];
                           d_spr_h      = cpu_data_in[5];
                           d_s          = cpu_data_in[4];
                           d_spr_pt_sel = cpu_data_in[3];
                           d_addr_incr  = cpu_data_in[2];
                           d_v          = cpu_data_in[1];
                           d_h          = cpu_data_in[0];
                      end
                  3'h1:
                    begin
                           d_spr_en      = cpu_data_in[4];
                           d_bg_en       = cpu_data_in[3];
                           d_spr_ls_clip = ~cpu_data_in[2];
                           d_bg_ls_clip  = ~cpu_data_in[1];
                    end
                   3'h2:
                   begin
                        d_cpu_d_out = { q_vblank, ri_spr_0_ex, ri_spr_of, 5'b00000 };
                        d_byte_sel  = 1'b0;
                        d_vblank    = 1'b0;
                   end            
                   3'h4:
                     begin
                     if(rw_select_in)
                        begin
                            ri_spr_ram_dout  = cpu_data_in;
                            ri_spr_ram_wr = 1'b1;
                            d_spr_ram_a    = q_spr_ram_a + 8'h01;
                       end
                      else
                        begin
                            ri_spr_ram_dout  = cpu_data_in;
                            ri_spr_ram_wr = 1'b1;
                            d_spr_ram_a    = q_spr_ram_a + 8'h01;
                        end
                     end   
                     3'h5:
                        begin
                        d_byte_sel = ~q_byte_sel;
                        if (~q_byte_sel)
                            begin
                               d_fh = cpu_data_in[2:0];
                               d_ht = cpu_data_in[7:3];
                               end
                         else
                               begin
                               d_fv = cpu_data_in[2:0];
                               d_vt = cpu_data_in[7:3];
                               end
                         end
                     3'h6:
                        begin
                            d_byte_sel = ~q_byte_sel;
                            if (~q_byte_sel)
                                begin
                                  d_fv      = { 1'b0, cpu_data_in[5:4] };
                                  d_v       = cpu_data_in[3];
                                  d_h       = cpu_data_in[2];
                                  d_vt[4:3] = cpu_data_in[1:0];
                                 end
                              else
                                  begin
                                  d_vt[2:0]       = cpu_data_in[7:5];
                                  d_ht            = cpu_data_in[4:0];
                                  d_upd_cntrs_out = 1'b1;
                                  end
                             end
                         3'h7:  
                             begin
                                if (vram_add_out[13:8] == 6'h3F)
                                    ri_pram_wr = 1'b1;
                                else
                                    ri_vram_wr = 1'b1;   
                                    ri_vram_dout   = cpu_data_in;
                                    ri_inc_addr = 1'b1;
                              end
                endcase
        end
      end
      
      assign cpu_data_out        = (~enable_in & select_in) ? q_cpu_d_out : 8'h00;
      assign ri_fv           = q_fv;
      assign ri_vt           = q_vt;
      assign ri_v            = q_v;
      assign ri_fh           = q_fh;
      assign ri_ht           = q_ht;
      assign ri_h            = q_h;
      assign ri_s            = q_s;
      //assign inc_addr_amt_out = q_addr_incr;
      assign ri_nmi_en      = q_nmi_en;
      assign vblank_out       = q_vblank;
      assign ri_bg_en       = q_bg_en;
      assign ri_bg_clip   = q_bg_ls_clip;
      assign ri_spr_clip  = q_spr_ls_clip;
      assign ri_spr_h        = q_spr_h; 
      assign ri_pattern_sel   = q_spr_pt_sel;
      assign ri_trans    = q_upd_cntrs_out;
      assign ri_spr_ram_aout    = q_spr_ram_a;
    
            
        
        
        
    
    
    
    
    
    
    
    
    
    
    
endmodule
