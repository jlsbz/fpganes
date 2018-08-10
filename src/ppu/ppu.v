`timescale 1ns / 1ps

module ppu
(
  input  wire        clk_in,        // 100MHz system clock signal
  input  wire        rst_in,        // reset signal
  input  wire [ 2:0] ri_sel_in,     // register interface reg select
  input  wire        ri_ncs_in,     // register interface enable
  input  wire        ri_r_nw_in,    // register interface read/write select
  input  wire [ 7:0] ri_d_in,       // register interface data in
  input  wire [ 7:0] vram_d_in,     // video memory data bus (input)
  output wire        hsync_out,     // vga hsync signal
  output wire        vsync_out,     // vga vsync signal
  output wire [ 2:0] r_out,         // vga red signal
  output wire [ 2:0] g_out,         // vga green signal
  output wire [ 1:0] b_out,         // vga blue signal
  output wire [ 7:0] ri_d_out,      // register interface data out
  output wire        nvbl_out,      // /VBL (low during vertical blank)
  output wire [13:0] vram_a_out,    // video memory address bus
  output wire [ 7:0] vram_d_out,    // video memory data bus (output)
  output wire        vram_wr_out    // video memory read/write select
);

//
// PPU_VGA: VGA output block.
//

wire [5:0] vga_sys_palette_idx;
wire [9:0] vga_nes_x;
wire [9:0] vga_nes_y;
wire [9:0] vga_nes_y_next;
wire       vga_pix_pulse;
wire       vga_vblank;

ppu_vga ppu_vga_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .sys_palette_idx_in(vga_sys_palette_idx),
  .hsync_out(hsync_out),
  .vsync_out(vsync_out),
  .r_out(r_out),
  .g_out(g_out),
  .b_out(b_out),
  .nes_x_out(vga_nes_x),
  .nes_y_out(vga_nes_y),
  .nes_y_next_out(vga_nes_y_next),
  .pix_pulse_out(vga_pix_pulse),
  .vblank_out(vga_vblank)
);


wire       ri_vblank;   // 2002 vbalnk
wire       ri_nmi_en;
wire [7:0] ri_vram_d_in;
wire [7:0] ri_pram_d_in;
wire       ri_vram_wr;
wire       ri_pram_wr;
wire [7:0] ri_spr_ram_in; // 2004
wire       ri_spr_of;   // 2002 overflow
wire       ri_spr_0_ex;  // 2002 sprite 0 exist
wire [7:0] ri_vram_dout;  
wire [2:0] ri_fv;
wire [4:0] ri_vt;
wire       ri_v;
wire [2:0] ri_fh;
wire [4:0] ri_ht;
wire       ri_h;
wire       ri_s;
wire       ri_spr_en;
wire       ri_bg_en;
wire       ri_spr_clip;
wire       ri_bg_clip;
wire       ri_spr_h;
wire       ri_trans;       // reg to contests
wire       ri_pattern_sel; // 2000 3        
wire       ri_inc_addr;
wire       ri_inc_addr_amt;// 2000 2 nametable
wire       ri_spr_ram_wr;
wire [7:0] ri_spr_ram_aout;
wire [7:0] ri_spr_ram_dout;

ppu_ri ppu_ri_blk(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .select_in(ri_sel_in),
    .enable_in(ri_ncs_in),     
    .rw_select_in(ri_r_nw_in),
    .cpu_data_in(ri_d_in),                   // register interface data in
    .vram_add_out(vram_a_out),             // video memory address bus
    .ri_vram_d_in(ri_vram_d_in),
    .ri_pram_d_in(ri_pram_d_in),
    .vblank_in(vga_vblank),
    .ri_spr_ram_in(ri_spr_ram_in),
    .ri_spr_of (ri_spr_of),
    .ri_spr_0_ex(ri_spr_0_ex),
    
    .cpu_data_out(ri_d_out),                 // register interface data out
    .ri_vram_dout(ri_vram_dout),
    .ri_vram_wr(ri_vram_wr),
    .ri_pram_wr(ri_pram_wr),
    .ri_fv(ri_fv),
    .ri_vt(ri_vt),
    .ri_v(ri_v),
    .ri_fh(ri_fh),
    .ri_ht(ri_ht),
    .ri_h(ri_h),
    .ri_s(ri_s),
    .ri_inc_addr(ri_inc_addr),
    .ri_inc_addr_amt(ri_inc_addr_amt),
    .ri_nmi_en(ri_nmi_en),
    .vblank_out(ri_vblank),
    .ri_spr_en(ri_spr_en),
    .ri_bg_en(ri_bg_en),
    .ri_spr_clip(ri_spr_clip),
    .ri_spr_h(ri_spr_h),
    .ri_bg_clip(ri_bg_clip),
    .ri_pattern_sel(ri_pattern_sel),
    .ri_trans(ri_trans),
    .ri_spr_ram_wr(ri_spr_ram_wr),
    .ri_spr_ram_aout(ri_spr_ram_aout),
    .ri_spr_ram_dout(ri_spr_ram_dout)
    
    );
    
    
    
wire [13:0] bg_vram_a;
wire [ 3:0] bg_palette_idx;


ppu_bg ppu_bg_blk(
            .clk_in(clk_in),
            .rst_in(rst_in),
            .ri_bg_en(ri_bg_en),
            .ri_bg_clip(ri_bg_clip),
            .ri_fv(ri_fv),
            .ri_vt(ri_vt),
            .ri_v(ri_v),
            .ri_fh(ri_fh),
            .ri_ht(ri_ht),
            .ri_h(ri_h),
            .ri_s(ri_s),
            .vga_nes_x(vga_nes_x),
            .vga_nes_y(vga_nes_y),
            .vga_nes_y_next(vga_nes_y_next),
            .vga_pix_pulse(vga_pix_pulse),
            .vram_d_in(vram_d_in),
            .ri_trans(ri_trans),
            .ri_inc_addr_in(ri_inc_addr),
            .ri_inc_addr_amt_in(ri_inc_addr_amt),
            .vram_a_out(bg_vram_a),
            .palette_idx_out(bg_palette_idx)
    );


wire  [3:0] spr_palette_idx;
wire        spr_primary;
wire        spr_priority;
wire [13:0] spr_vram_a;
wire        spr_vram_req;

ppu_spr ppu_spr_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .en_in(ri_spr_en),
  .ls_clip_in(ri_spr_clip),
  .spr_h_in(ri_spr_h),
  .spr_pt_sel_in(ri_pattern_sel),
  .oam_a_in(ri_spr_ram_aout),
  .oam_d_in(ri_spr_ram_dout),
  .oam_wr_in(ri_spr_ram_wr),
  .nes_x_in(vga_nes_x),
  .nes_y_in(vga_nes_y),
  .nes_y_next_in(vga_nes_y_next),
  .pix_pulse_in(vga_pix_pulse),
  .vram_d_in(vram_d_in),
  .oam_d_out(ri_spr_0_ex),
  .overflow_out(ri_spr_of),
  .palette_idx_out(spr_palette_idx),
  .primary_out(spr_primary),
  .priority_out(spr_priority),
  .vram_a_out(spr_vram_a),
  .vram_req_out(spr_vram_req)
);


reg  [5:0] palette_ram [31:0];

`define PRAM_A(addr) ((addr & 5'h03) ? addr :  (addr & 5'h0f))

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        palette_ram[`PRAM_A(5'h00)] <= 6'h09;
        palette_ram[`PRAM_A(5'h01)] <= 6'h01;
        palette_ram[`PRAM_A(5'h02)] <= 6'h00;
        palette_ram[`PRAM_A(5'h03)] <= 6'h01;
        palette_ram[`PRAM_A(5'h04)] <= 6'h00;
        palette_ram[`PRAM_A(5'h05)] <= 6'h02;
        palette_ram[`PRAM_A(5'h06)] <= 6'h02;
        palette_ram[`PRAM_A(5'h07)] <= 6'h0d;
        palette_ram[`PRAM_A(5'h08)] <= 6'h08;
        palette_ram[`PRAM_A(5'h09)] <= 6'h10;
        palette_ram[`PRAM_A(5'h0a)] <= 6'h08;
        palette_ram[`PRAM_A(5'h0b)] <= 6'h24;
        palette_ram[`PRAM_A(5'h0c)] <= 6'h00;
        palette_ram[`PRAM_A(5'h0d)] <= 6'h00;
        palette_ram[`PRAM_A(5'h0e)] <= 6'h04;
        palette_ram[`PRAM_A(5'h0f)] <= 6'h2c;
        palette_ram[`PRAM_A(5'h11)] <= 6'h01;
        palette_ram[`PRAM_A(5'h12)] <= 6'h34;
        palette_ram[`PRAM_A(5'h13)] <= 6'h03;
        palette_ram[`PRAM_A(5'h15)] <= 6'h04;
        palette_ram[`PRAM_A(5'h16)] <= 6'h00;
        palette_ram[`PRAM_A(5'h17)] <= 6'h14;
        palette_ram[`PRAM_A(5'h19)] <= 6'h3a;
        palette_ram[`PRAM_A(5'h1a)] <= 6'h00;
        palette_ram[`PRAM_A(5'h1b)] <= 6'h02;
        palette_ram[`PRAM_A(5'h1d)] <= 6'h20;
        palette_ram[`PRAM_A(5'h1e)] <= 6'h2c;
        palette_ram[`PRAM_A(5'h1f)] <= 6'h08;
      end
    else if (ri_pram_wr)
      palette_ram[`PRAM_A(vram_a_out[4:0])] <= ri_vram_dout[5:0];
  end
    
    assign ri_vram_d_in = vram_d_in;
    assign ri_pram_d_in = palette_ram[`PRAM_A(vram_a_out[4:0])];
  
  assign vram_a_out  = (ri_spr_en) ? spr_vram_a : bg_vram_a;
  assign vram_d_out  = ri_vram_dout;
  assign vram_wr_out = ri_vram_wr;
  
  reg  q_pri_obj;
  wire d_pri_obj;
  
  always @(posedge clk_in)
    begin
      if (rst_in)
        q_pri_obj <= 1'b0;
      else
        q_pri_obj <= d_pri_obj;
    end
  
  wire spr_foreground;
  wire spr_trans;
  wire bg_trans;
  
  assign spr_foreground  = ~spr_priority;
  assign spr_trans       = ~|spr_palette_idx[1:0];
  assign bg_trans        = ~|bg_palette_idx[1:0];
  
  assign d_pri_obj = (vga_nes_y_next == 0)                    ? 1'b0 :
                         (spr_primary && !spr_trans && !bg_trans) ? 1'b1 : q_pri_obj;
  
  assign vga_sys_palette_idx =
    ((spr_foreground || bg_trans) && !spr_trans) ? palette_ram[{ 1'b1, spr_palette_idx }] :
    (!bg_trans)                                  ? palette_ram[{ 1'b0, bg_palette_idx }]  :
                                                   palette_ram[5'h00];
  
  assign ri_spr_0_ex = q_pri_obj;
  
  assign nvbl_out = (ri_nmi_en) ? 1'b1:
                    ~(ri_vblank)? 1'b1:1'b0;

    
    

endmodule
