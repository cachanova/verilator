// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Leela Pakanati
// SPDX-License-Identifier: CC0-1.0

// Issue #6998 - Nested interface ports through interface arrays
// Similar structure to t_interface_nested_port.v, but with interface arrays.
// Tests different array sizes: [1:0], [0:0] (single-element), [2:0] (3-element)
// Note: 2-D interface arrays are unsupported by Verilator

interface l0_if #(parameter int W = 8);
  logic [W-1:0] tb_in;
  logic [W-1:0] dut_out;
endinterface

interface l1_if #(parameter int W = 8, parameter int L0A_W = 8);
  logic [W-1:0] tb_in;
  logic [W-1:0] dut_out;
  l0_if #(L0A_W) l0a[1:0]();  // 2-element array
  l0_if          l0b();       // scalar (default width)
  l0_if #(L0A_W) l0c[0:0]();  // single-element array
  l0_if #(L0A_W) l0d[2:0]();  // 3-element array
endinterface

interface l2_if #(parameter int W = 8, parameter int L0A_W = 8);
  logic [W-1:0] tb_in;
  logic [W-1:0] dut_out;
  l1_if #(W*2, L0A_W) l1[1:0]();  // 2-element array
endinterface

interface l3_if #(parameter int W = 8, parameter int L0A_W = 8);
  logic [W-1:0] tb_in;
  logic [W-1:0] dut_out;
  l2_if #(W*2, L0A_W) l2[1:0]();  // 2-element array
endinterface

// 3-element outer array interface
interface arr3_if #(parameter int W = 8);
  logic [W-1:0] tb_in;
  logic [W-1:0] dut_out;
  l0_if #(W) elem[2:0]();  // 3-element array
endinterface

module l0_handler #(parameter int W = 8)(
  input  logic         clk,
  l0_if #(W)           l0,
  output logic [W-1:0] dout
);
  always_ff @(posedge clk) l0.dut_out <= l0.tb_in ^ W'('1);
  assign dout = l0.dut_out;
endmodule

module l1_handler #(parameter int W = 8, parameter int L0A_W = 8)(
  input  logic             clk,
  l1_if #(W, L0A_W)        l1,
  output logic [W-1:0]     l1_dout,
  output logic [L0A_W-1:0] l0a0_dout,
  output logic [L0A_W-1:0] l0a1_dout,
  output logic [7:0]       l0b_dout,
  output logic [L0A_W-1:0] l0c0_dout,   // single-element array
  output logic [L0A_W-1:0] l0d0_dout,   // 3-element array [0]
  output logic [L0A_W-1:0] l0d1_dout,   // 3-element array [1]
  output logic [L0A_W-1:0] l0d2_dout    // 3-element array [2]
);
  always_ff @(posedge clk) l1.dut_out <= l1.tb_in ^ W'('1);
  assign l1_dout = l1.dut_out;
  l0_handler #(L0A_W) m_l0a0 (.clk(clk), .l0(l1.l0a[0]), .dout(l0a0_dout));
  l0_handler #(L0A_W) m_l0a1 (.clk(clk), .l0(l1.l0a[1]), .dout(l0a1_dout));
  l0_handler #(8)     m_l0b  (.clk(clk), .l0(l1.l0b),    .dout(l0b_dout));
  l0_handler #(L0A_W) m_l0c0 (.clk(clk), .l0(l1.l0c[0]), .dout(l0c0_dout));  // single-element
  l0_handler #(L0A_W) m_l0d0 (.clk(clk), .l0(l1.l0d[0]), .dout(l0d0_dout));  // 3-elem [0]
  l0_handler #(L0A_W) m_l0d1 (.clk(clk), .l0(l1.l0d[1]), .dout(l0d1_dout));  // 3-elem [1]
  l0_handler #(L0A_W) m_l0d2 (.clk(clk), .l0(l1.l0d[2]), .dout(l0d2_dout));  // 3-elem [2]
endmodule

module l2_handler #(parameter int W = 8, parameter int L0A_W = 8)(
  input  logic             clk,
  l2_if #(W, L0A_W)        l2,
  output logic [W-1:0]     l2_dout,
  output logic [W*2-1:0]   l1_0_dout,
  output logic [L0A_W-1:0] l0a0_0_dout,
  output logic [L0A_W-1:0] l0a1_1_dout,
  output logic [7:0]       l0b_1_dout,
  output logic [L0A_W-1:0] l0c0_0_dout,  // single-element from l1[0]
  output logic [L0A_W-1:0] l0d2_1_dout   // 3-element [2] from l1[1]
);
  always_ff @(posedge clk) l2.dut_out <= l2.tb_in ^ W'('1);
  assign l2_dout = l2.dut_out;
  l1_handler #(W*2, L0A_W) m_l1_0 (
    .clk(clk), .l1(l2.l1[0]),
    .l1_dout(l1_0_dout), .l0a0_dout(l0a0_0_dout),
    .l0a1_dout(), .l0b_dout(),
    .l0c0_dout(l0c0_0_dout), .l0d0_dout(), .l0d1_dout(), .l0d2_dout()
  );
  l1_handler #(W*2, L0A_W) m_l1_1 (
    .clk(clk), .l1(l2.l1[1]),
    .l1_dout(), .l0a0_dout(),
    .l0a1_dout(l0a1_1_dout), .l0b_dout(l0b_1_dout),
    .l0c0_dout(), .l0d0_dout(), .l0d1_dout(), .l0d2_dout(l0d2_1_dout)
  );
endmodule

module l2_array_handler #(parameter int W = 8, parameter int L0A_W = 8)(
  input  logic             clk,
  l2_if #(W, L0A_W)        l2s[1:0],
  output logic [W-1:0]     l2a_dout,
  output logic [W*2-1:0]   l2a_l1_0_dout,
  output logic [L0A_W-1:0] l2a_l0a0_0_dout,
  output logic [L0A_W-1:0] l2a_l0a1_1_dout,
  output logic [7:0]       l2a_l0b_1_dout,
  output logic [L0A_W-1:0] l2a_l0c0_0_dout,
  output logic [L0A_W-1:0] l2a_l0d2_1_dout,
  output logic [W-1:0]     l2b_dout,
  output logic [W*2-1:0]   l2b_l1_0_dout,
  output logic [L0A_W-1:0] l2b_l0a0_0_dout,
  output logic [L0A_W-1:0] l2b_l0a1_1_dout,
  output logic [7:0]       l2b_l0b_1_dout,
  output logic [L0A_W-1:0] l2b_l0c0_0_dout,
  output logic [L0A_W-1:0] l2b_l0d2_1_dout
);
  l2_handler #(W, L0A_W) m_l2a (
    .clk(clk), .l2(l2s[0]),
    .l2_dout(l2a_dout),
    .l1_0_dout(l2a_l1_0_dout), .l0a0_0_dout(l2a_l0a0_0_dout),
    .l0a1_1_dout(l2a_l0a1_1_dout), .l0b_1_dout(l2a_l0b_1_dout),
    .l0c0_0_dout(l2a_l0c0_0_dout), .l0d2_1_dout(l2a_l0d2_1_dout)
  );
  l2_handler #(W, L0A_W) m_l2b (
    .clk(clk), .l2(l2s[1]),
    .l2_dout(l2b_dout),
    .l1_0_dout(l2b_l1_0_dout), .l0a0_0_dout(l2b_l0a0_0_dout),
    .l0a1_1_dout(l2b_l0a1_1_dout), .l0b_1_dout(l2b_l0b_1_dout),
    .l0c0_0_dout(l2b_l0c0_0_dout), .l0d2_1_dout(l2b_l0d2_1_dout)
  );
endmodule

module l3_handler #(parameter int W = 8, parameter int L0A_W = 8)(
  input  logic             clk,
  l3_if #(W, L0A_W)        l3,
  output logic [W-1:0]     l3_dout,
  output logic [W*2-1:0]   l2a_dout,
  output logic [W*4-1:0]   l2a_l1_0_dout,
  output logic [L0A_W-1:0] l2a_l0a0_0_dout,
  output logic [L0A_W-1:0] l2a_l0a1_1_dout,
  output logic [7:0]       l2a_l0b_1_dout,
  output logic [L0A_W-1:0] l2a_l0c0_0_dout,
  output logic [L0A_W-1:0] l2a_l0d2_1_dout,
  output logic [W*2-1:0]   l2b_dout,
  output logic [W*4-1:0]   l2b_l1_0_dout,
  output logic [L0A_W-1:0] l2b_l0a0_0_dout,
  output logic [L0A_W-1:0] l2b_l0a1_1_dout,
  output logic [7:0]       l2b_l0b_1_dout,
  output logic [L0A_W-1:0] l2b_l0c0_0_dout,
  output logic [L0A_W-1:0] l2b_l0d2_1_dout
);
  always_ff @(posedge clk) l3.dut_out <= l3.tb_in ^ W'('1);
  assign l3_dout = l3.dut_out;
  l2_array_handler #(W*2, L0A_W) m_l2 (
    .clk(clk), .l2s(l3.l2),
    .l2a_dout(l2a_dout),
    .l2a_l1_0_dout(l2a_l1_0_dout), .l2a_l0a0_0_dout(l2a_l0a0_0_dout),
    .l2a_l0a1_1_dout(l2a_l0a1_1_dout), .l2a_l0b_1_dout(l2a_l0b_1_dout),
    .l2a_l0c0_0_dout(l2a_l0c0_0_dout), .l2a_l0d2_1_dout(l2a_l0d2_1_dout),
    .l2b_dout(l2b_dout),
    .l2b_l1_0_dout(l2b_l1_0_dout), .l2b_l0a0_0_dout(l2b_l0a0_0_dout),
    .l2b_l0a1_1_dout(l2b_l0a1_1_dout), .l2b_l0b_1_dout(l2b_l0b_1_dout),
    .l2b_l0c0_0_dout(l2b_l0c0_0_dout), .l2b_l0d2_1_dout(l2b_l0d2_1_dout)
  );
endmodule

// Handler for 3-element array interface
module arr3_handler #(parameter int W = 8)(
  input  logic         clk,
  arr3_if #(W)         arr,
  output logic [W-1:0] arr_dout,
  output logic [W-1:0] elem0_dout,
  output logic [W-1:0] elem1_dout,
  output logic [W-1:0] elem2_dout
);
  always_ff @(posedge clk) arr.dut_out <= arr.tb_in ^ W'('1);
  assign arr_dout = arr.dut_out;
  l0_handler #(W) m_elem0 (.clk(clk), .l0(arr.elem[0]), .dout(elem0_dout));
  l0_handler #(W) m_elem1 (.clk(clk), .l0(arr.elem[1]), .dout(elem1_dout));
  l0_handler #(W) m_elem2 (.clk(clk), .l0(arr.elem[2]), .dout(elem2_dout));
endmodule

module t;
  logic clk = 0;
  int   cyc = 0;

  localparam int TOP_W = 4;
  localparam int L0A_W = 12;
  localparam int ARR3_W = 6;

  // Main nested interface instance
  l3_if #(TOP_W, L0A_W) inst();

  // 3-element array interface instance
  arr3_if #(ARR3_W) inst_3();

  // Outputs for main l3 hierarchy
  logic [TOP_W-1:0]     l3_dout;
  logic [TOP_W*2-1:0]   l2a_dout;
  logic [TOP_W*4-1:0]   l2a_l1_0_dout;
  logic [L0A_W-1:0]     l2a_l0a0_0_dout;
  logic [L0A_W-1:0]     l2a_l0a1_1_dout;
  logic [7:0]           l2a_l0b_1_dout;
  logic [L0A_W-1:0]     l2a_l0c0_0_dout;  // single-element array
  logic [L0A_W-1:0]     l2a_l0d2_1_dout;  // 3-element array [2]
  logic [TOP_W*2-1:0]   l2b_dout;
  logic [TOP_W*4-1:0]   l2b_l1_0_dout;
  logic [L0A_W-1:0]     l2b_l0a0_0_dout;
  logic [L0A_W-1:0]     l2b_l0a1_1_dout;
  logic [7:0]           l2b_l0b_1_dout;
  logic [L0A_W-1:0]     l2b_l0c0_0_dout;
  logic [L0A_W-1:0]     l2b_l0d2_1_dout;

  // Outputs for 3-element array
  logic [ARR3_W-1:0]    arr3_dout;
  logic [ARR3_W-1:0]    arr3_elem0_dout;
  logic [ARR3_W-1:0]    arr3_elem1_dout;
  logic [ARR3_W-1:0]    arr3_elem2_dout;

  l3_handler #(TOP_W, L0A_W) m_l3 (
    .clk(clk), .l3(inst),
    .l3_dout(l3_dout),
    .l2a_dout(l2a_dout),
    .l2a_l1_0_dout(l2a_l1_0_dout), .l2a_l0a0_0_dout(l2a_l0a0_0_dout),
    .l2a_l0a1_1_dout(l2a_l0a1_1_dout), .l2a_l0b_1_dout(l2a_l0b_1_dout),
    .l2a_l0c0_0_dout(l2a_l0c0_0_dout), .l2a_l0d2_1_dout(l2a_l0d2_1_dout),
    .l2b_dout(l2b_dout),
    .l2b_l1_0_dout(l2b_l1_0_dout), .l2b_l0a0_0_dout(l2b_l0a0_0_dout),
    .l2b_l0a1_1_dout(l2b_l0a1_1_dout), .l2b_l0b_1_dout(l2b_l0b_1_dout),
    .l2b_l0c0_0_dout(l2b_l0c0_0_dout), .l2b_l0d2_1_dout(l2b_l0d2_1_dout)
  );

  arr3_handler #(ARR3_W) m_arr3 (
    .clk(clk), .arr(inst_3),
    .arr_dout(arr3_dout),
    .elem0_dout(arr3_elem0_dout), .elem1_dout(arr3_elem1_dout),
    .elem2_dout(arr3_elem2_dout)
  );

  always #5 clk = ~clk;

  always_ff @(posedge clk) begin
    // Main l3 hierarchy stimulus
    inst.tb_in <= cyc[TOP_W-1:0];

    inst.l2[0].tb_in <= cyc[TOP_W*2-1:0] + (TOP_W*2)'(1);
    inst.l2[0].l1[0].tb_in <= cyc[TOP_W*4-1:0] + (TOP_W*4)'(2);
    inst.l2[0].l1[0].l0a[0].tb_in <= cyc[L0A_W-1:0] + L0A_W'(3);
    inst.l2[0].l1[1].l0a[1].tb_in <= cyc[L0A_W-1:0] + L0A_W'(4);
    inst.l2[0].l1[1].l0b.tb_in <= cyc[7:0] + 8'd5;
    inst.l2[0].l1[0].l0c[0].tb_in <= cyc[L0A_W-1:0] + L0A_W'(11);  // single-element
    inst.l2[0].l1[1].l0d[2].tb_in <= cyc[L0A_W-1:0] + L0A_W'(12);  // 3-element [2]

    inst.l2[1].tb_in <= cyc[TOP_W*2-1:0] + (TOP_W*2)'(6);
    inst.l2[1].l1[0].tb_in <= cyc[TOP_W*4-1:0] + (TOP_W*4)'(7);
    inst.l2[1].l1[0].l0a[0].tb_in <= cyc[L0A_W-1:0] + L0A_W'(8);
    inst.l2[1].l1[1].l0a[1].tb_in <= cyc[L0A_W-1:0] + L0A_W'(9);
    inst.l2[1].l1[1].l0b.tb_in <= cyc[7:0] + 8'd10;
    inst.l2[1].l1[0].l0c[0].tb_in <= cyc[L0A_W-1:0] + L0A_W'(13);
    inst.l2[1].l1[1].l0d[2].tb_in <= cyc[L0A_W-1:0] + L0A_W'(14);

    // 3-element array stimulus
    inst_3.tb_in <= cyc[ARR3_W-1:0] + ARR3_W'(30);
    inst_3.elem[0].tb_in <= cyc[ARR3_W-1:0] + ARR3_W'(31);
    inst_3.elem[1].tb_in <= cyc[ARR3_W-1:0] + ARR3_W'(32);
    inst_3.elem[2].tb_in <= cyc[ARR3_W-1:0] + ARR3_W'(33);
  end

  // Expected values for l3 hierarchy
  logic [TOP_W-1:0]     exp_l3_dout;
  logic [TOP_W*2-1:0]   exp_l2a_dout;
  logic [TOP_W*4-1:0]   exp_l2a_l1_0_dout;
  logic [L0A_W-1:0]     exp_l2a_l0a0_0_dout;
  logic [L0A_W-1:0]     exp_l2a_l0a1_1_dout;
  logic [7:0]           exp_l2a_l0b_1_dout;
  logic [L0A_W-1:0]     exp_l2a_l0c0_0_dout;
  logic [L0A_W-1:0]     exp_l2a_l0d2_1_dout;
  logic [TOP_W*2-1:0]   exp_l2b_dout;
  logic [TOP_W*4-1:0]   exp_l2b_l1_0_dout;
  logic [L0A_W-1:0]     exp_l2b_l0a0_0_dout;
  logic [L0A_W-1:0]     exp_l2b_l0a1_1_dout;
  logic [7:0]           exp_l2b_l0b_1_dout;
  logic [L0A_W-1:0]     exp_l2b_l0c0_0_dout;
  logic [L0A_W-1:0]     exp_l2b_l0d2_1_dout;

  // Expected values for 3-element array
  logic [ARR3_W-1:0]    exp_arr3_dout;
  logic [ARR3_W-1:0]    exp_arr3_elem0_dout;
  logic [ARR3_W-1:0]    exp_arr3_elem1_dout;
  logic [ARR3_W-1:0]    exp_arr3_elem2_dout;

  always_ff @(posedge clk) begin
    // l3 hierarchy expected
    exp_l3_dout <= inst.tb_in ^ TOP_W'('1);

    exp_l2a_dout <= inst.l2[0].tb_in ^ (TOP_W*2)'('1);
    exp_l2a_l1_0_dout <= inst.l2[0].l1[0].tb_in ^ (TOP_W*4)'('1);
    exp_l2a_l0a0_0_dout <= inst.l2[0].l1[0].l0a[0].tb_in ^ L0A_W'('1);
    exp_l2a_l0a1_1_dout <= inst.l2[0].l1[1].l0a[1].tb_in ^ L0A_W'('1);
    exp_l2a_l0b_1_dout <= inst.l2[0].l1[1].l0b.tb_in ^ 8'hFF;
    exp_l2a_l0c0_0_dout <= inst.l2[0].l1[0].l0c[0].tb_in ^ L0A_W'('1);
    exp_l2a_l0d2_1_dout <= inst.l2[0].l1[1].l0d[2].tb_in ^ L0A_W'('1);

    exp_l2b_dout <= inst.l2[1].tb_in ^ (TOP_W*2)'('1);
    exp_l2b_l1_0_dout <= inst.l2[1].l1[0].tb_in ^ (TOP_W*4)'('1);
    exp_l2b_l0a0_0_dout <= inst.l2[1].l1[0].l0a[0].tb_in ^ L0A_W'('1);
    exp_l2b_l0a1_1_dout <= inst.l2[1].l1[1].l0a[1].tb_in ^ L0A_W'('1);
    exp_l2b_l0b_1_dout <= inst.l2[1].l1[1].l0b.tb_in ^ 8'hFF;
    exp_l2b_l0c0_0_dout <= inst.l2[1].l1[0].l0c[0].tb_in ^ L0A_W'('1);
    exp_l2b_l0d2_1_dout <= inst.l2[1].l1[1].l0d[2].tb_in ^ L0A_W'('1);

    // 3-element array expected
    exp_arr3_dout <= inst_3.tb_in ^ ARR3_W'('1);
    exp_arr3_elem0_dout <= inst_3.elem[0].tb_in ^ ARR3_W'('1);
    exp_arr3_elem1_dout <= inst_3.elem[1].tb_in ^ ARR3_W'('1);
    exp_arr3_elem2_dout <= inst_3.elem[2].tb_in ^ ARR3_W'('1);
  end

  always @(posedge clk) begin
    cyc <= cyc + 1;

    if (cyc > 3) begin
      if (l3_dout !== exp_l3_dout) begin
        $display("FAIL cyc=%0d: l3_dout=%h expected %h", cyc, l3_dout, exp_l3_dout);
        $stop;
      end
      if (l2a_dout !== exp_l2a_dout) begin
        $display("FAIL cyc=%0d: l2a_dout=%h expected %h", cyc, l2a_dout, exp_l2a_dout);
        $stop;
      end
      if (l2a_l1_0_dout !== exp_l2a_l1_0_dout) begin
        $display("FAIL cyc=%0d: l2a_l1_0_dout=%h expected %h",
                 cyc, l2a_l1_0_dout, exp_l2a_l1_0_dout);
        $stop;
      end
      if (l2a_l0a0_0_dout !== exp_l2a_l0a0_0_dout) begin
        $display("FAIL cyc=%0d: l2a_l0a0_0_dout=%h expected %h",
                 cyc, l2a_l0a0_0_dout, exp_l2a_l0a0_0_dout);
        $stop;
      end
      if (l2a_l0a1_1_dout !== exp_l2a_l0a1_1_dout) begin
        $display("FAIL cyc=%0d: l2a_l0a1_1_dout=%h expected %h",
                 cyc, l2a_l0a1_1_dout, exp_l2a_l0a1_1_dout);
        $stop;
      end
      if (l2a_l0b_1_dout !== exp_l2a_l0b_1_dout) begin
        $display("FAIL cyc=%0d: l2a_l0b_1_dout=%h expected %h",
                 cyc, l2a_l0b_1_dout, exp_l2a_l0b_1_dout);
        $stop;
      end

      if (l2b_dout !== exp_l2b_dout) begin
        $display("FAIL cyc=%0d: l2b_dout=%h expected %h", cyc, l2b_dout, exp_l2b_dout);
        $stop;
      end
      if (l2b_l1_0_dout !== exp_l2b_l1_0_dout) begin
        $display("FAIL cyc=%0d: l2b_l1_0_dout=%h expected %h",
                 cyc, l2b_l1_0_dout, exp_l2b_l1_0_dout);
        $stop;
      end
      if (l2b_l0a0_0_dout !== exp_l2b_l0a0_0_dout) begin
        $display("FAIL cyc=%0d: l2b_l0a0_0_dout=%h expected %h",
                 cyc, l2b_l0a0_0_dout, exp_l2b_l0a0_0_dout);
        $stop;
      end
      if (l2b_l0a1_1_dout !== exp_l2b_l0a1_1_dout) begin
        $display("FAIL cyc=%0d: l2b_l0a1_1_dout=%h expected %h",
                 cyc, l2b_l0a1_1_dout, exp_l2b_l0a1_1_dout);
        $stop;
      end
      if (l2b_l0b_1_dout !== exp_l2b_l0b_1_dout) begin
        $display("FAIL cyc=%0d: l2b_l0b_1_dout=%h expected %h",
                 cyc, l2b_l0b_1_dout, exp_l2b_l0b_1_dout);
        $stop;
      end

      // Single-element array checks
      if (l2a_l0c0_0_dout !== exp_l2a_l0c0_0_dout) begin
        $display("FAIL cyc=%0d: l2a_l0c0_0_dout=%h expected %h",
                 cyc, l2a_l0c0_0_dout, exp_l2a_l0c0_0_dout);
        $stop;
      end
      if (l2b_l0c0_0_dout !== exp_l2b_l0c0_0_dout) begin
        $display("FAIL cyc=%0d: l2b_l0c0_0_dout=%h expected %h",
                 cyc, l2b_l0c0_0_dout, exp_l2b_l0c0_0_dout);
        $stop;
      end

      // 3-element array checks
      if (l2a_l0d2_1_dout !== exp_l2a_l0d2_1_dout) begin
        $display("FAIL cyc=%0d: l2a_l0d2_1_dout=%h expected %h",
                 cyc, l2a_l0d2_1_dout, exp_l2a_l0d2_1_dout);
        $stop;
      end
      if (l2b_l0d2_1_dout !== exp_l2b_l0d2_1_dout) begin
        $display("FAIL cyc=%0d: l2b_l0d2_1_dout=%h expected %h",
                 cyc, l2b_l0d2_1_dout, exp_l2b_l0d2_1_dout);
        $stop;
      end

      // 3-element outer array checks
      if (arr3_dout !== exp_arr3_dout) begin
        $display("FAIL cyc=%0d: arr3_dout=%h expected %h",
                 cyc, arr3_dout, exp_arr3_dout);
        $stop;
      end
      if (arr3_elem0_dout !== exp_arr3_elem0_dout) begin
        $display("FAIL cyc=%0d: arr3_elem0_dout=%h expected %h",
                 cyc, arr3_elem0_dout, exp_arr3_elem0_dout);
        $stop;
      end
      if (arr3_elem1_dout !== exp_arr3_elem1_dout) begin
        $display("FAIL cyc=%0d: arr3_elem1_dout=%h expected %h",
                 cyc, arr3_elem1_dout, exp_arr3_elem1_dout);
        $stop;
      end
      if (arr3_elem2_dout !== exp_arr3_elem2_dout) begin
        $display("FAIL cyc=%0d: arr3_elem2_dout=%h expected %h",
                 cyc, arr3_elem2_dout, exp_arr3_elem2_dout);
        $stop;
      end
    end

    if (cyc == 20) begin
      $write("*-* All Finished *-*\n");
      $finish;
    end
  end
endmodule
