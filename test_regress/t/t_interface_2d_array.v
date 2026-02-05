// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Leela Pakanati
// SPDX-License-Identifier: CC0-1.0

// Test for 2-D interface arrays (multi-dimensional interface instantiation)
// Tests instantiation like: simple_if iface[1:0][2:0]()

interface simple_if #(parameter int W = 8);
  logic [W-1:0] data;
  logic [W-1:0] result;
endinterface

// Handler that operates on a single interface
module handler #(parameter int W = 8)(
  input logic clk,
  simple_if iface
);
  always_ff @(posedge clk) iface.result <= iface.data ^ W'('1);
endmodule

// Module with 1-D interface array port
module handler_1d_arr #(parameter int W = 8, parameter int N = 2)(
  input logic clk,
  simple_if iface[N-1:0]
);
  genvar i;
  generate
    for (i = 0; i < N; i++) begin : gen_handlers
      handler #(W) h(.clk(clk), .iface(iface[i]));
    end
  endgenerate
endmodule

// Module with 2-D interface array port (row of interface arrays)
module handler_2d_row #(parameter int W = 8, parameter int ROWS = 2, parameter int COLS = 3)(
  input logic clk,
  simple_if iface[ROWS-1:0][COLS-1:0]
);
  genvar r;
  generate
    for (r = 0; r < ROWS; r++) begin : gen_rows
      handler_1d_arr #(W, COLS) h_row(.clk(clk), .iface(iface[r]));
    end
  endgenerate
endmodule

module t;
  logic clk = 0;
  int cyc = 0;

  localparam int W = 8;
  localparam int ROWS = 2;
  localparam int COLS = 3;

  // 2-D interface array instantiation
  simple_if #(W) arr2d[ROWS-1:0][COLS-1:0]();

  // Also test smaller 2-D arrays
  simple_if #(W) arr2d_small[1:0][1:0]();

  // Single-element 2-D array (degenerate case)
  simple_if #(W) arr2d_one[0:0][0:0]();

  // Outputs from handlers
  logic [W-1:0] expected[ROWS-1:0][COLS-1:0];
  logic [W-1:0] expected_small[1:0][1:0];
  logic [W-1:0] expected_one;

  // Instantiate handlers that connect to individual elements
  handler #(W) h00(.clk(clk), .iface(arr2d[0][0]));
  handler #(W) h01(.clk(clk), .iface(arr2d[0][1]));
  handler #(W) h02(.clk(clk), .iface(arr2d[0][2]));
  handler #(W) h10(.clk(clk), .iface(arr2d[1][0]));
  handler #(W) h11(.clk(clk), .iface(arr2d[1][1]));
  handler #(W) h12(.clk(clk), .iface(arr2d[1][2]));

  // Connect to small 2-D array
  handler #(W) hs00(.clk(clk), .iface(arr2d_small[0][0]));
  handler #(W) hs01(.clk(clk), .iface(arr2d_small[0][1]));
  handler #(W) hs10(.clk(clk), .iface(arr2d_small[1][0]));
  handler #(W) hs11(.clk(clk), .iface(arr2d_small[1][1]));

  // Connect to single-element 2-D array
  handler #(W) hone(.clk(clk), .iface(arr2d_one[0][0]));

  always #5 clk = ~clk;

  // Drive inputs - explicit assignments (no loop variables in array indices)
  always_ff @(posedge clk) begin
    // Main 2-D array [1:0][2:0]
    arr2d[0][0].data <= cyc[W-1:0];
    arr2d[0][1].data <= cyc[W-1:0] + 8'd1;
    arr2d[0][2].data <= cyc[W-1:0] + 8'd2;
    arr2d[1][0].data <= cyc[W-1:0] + 8'd10;
    arr2d[1][1].data <= cyc[W-1:0] + 8'd11;
    arr2d[1][2].data <= cyc[W-1:0] + 8'd12;

    // Small 2-D array [1:0][1:0]
    arr2d_small[0][0].data <= cyc[W-1:0];
    arr2d_small[0][1].data <= cyc[W-1:0] + 8'd10;
    arr2d_small[1][0].data <= cyc[W-1:0] + 8'd100;
    arr2d_small[1][1].data <= cyc[W-1:0] + 8'd110;

    // Single-element 2-D array
    arr2d_one[0][0].data <= cyc[W-1:0] + 8'd200;
  end

  // Compute expected values
  always_ff @(posedge clk) begin
    // Main 2-D array expected
    expected[0][0] <= arr2d[0][0].data ^ W'('1);
    expected[0][1] <= arr2d[0][1].data ^ W'('1);
    expected[0][2] <= arr2d[0][2].data ^ W'('1);
    expected[1][0] <= arr2d[1][0].data ^ W'('1);
    expected[1][1] <= arr2d[1][1].data ^ W'('1);
    expected[1][2] <= arr2d[1][2].data ^ W'('1);

    // Small 2-D array expected
    expected_small[0][0] <= arr2d_small[0][0].data ^ W'('1);
    expected_small[0][1] <= arr2d_small[0][1].data ^ W'('1);
    expected_small[1][0] <= arr2d_small[1][0].data ^ W'('1);
    expected_small[1][1] <= arr2d_small[1][1].data ^ W'('1);

    // Single-element expected
    expected_one <= arr2d_one[0][0].data ^ W'('1);
  end

  // Check outputs
  always @(posedge clk) begin
    cyc <= cyc + 1;

    if (cyc > 3) begin
      // Check main 2-D array
      if (arr2d[0][0].result !== expected[0][0]) begin
        $display("FAIL cyc=%0d: arr2d[0][0].result=%h expected %h",
                 cyc, arr2d[0][0].result, expected[0][0]);
        $stop;
      end
      if (arr2d[0][1].result !== expected[0][1]) begin
        $display("FAIL cyc=%0d: arr2d[0][1].result=%h expected %h",
                 cyc, arr2d[0][1].result, expected[0][1]);
        $stop;
      end
      if (arr2d[0][2].result !== expected[0][2]) begin
        $display("FAIL cyc=%0d: arr2d[0][2].result=%h expected %h",
                 cyc, arr2d[0][2].result, expected[0][2]);
        $stop;
      end
      if (arr2d[1][0].result !== expected[1][0]) begin
        $display("FAIL cyc=%0d: arr2d[1][0].result=%h expected %h",
                 cyc, arr2d[1][0].result, expected[1][0]);
        $stop;
      end
      if (arr2d[1][1].result !== expected[1][1]) begin
        $display("FAIL cyc=%0d: arr2d[1][1].result=%h expected %h",
                 cyc, arr2d[1][1].result, expected[1][1]);
        $stop;
      end
      if (arr2d[1][2].result !== expected[1][2]) begin
        $display("FAIL cyc=%0d: arr2d[1][2].result=%h expected %h",
                 cyc, arr2d[1][2].result, expected[1][2]);
        $stop;
      end

      // Check small 2-D array
      if (arr2d_small[0][0].result !== expected_small[0][0]) begin
        $display("FAIL cyc=%0d: arr2d_small[0][0].result=%h expected %h",
                 cyc, arr2d_small[0][0].result, expected_small[0][0]);
        $stop;
      end
      if (arr2d_small[0][1].result !== expected_small[0][1]) begin
        $display("FAIL cyc=%0d: arr2d_small[0][1].result=%h expected %h",
                 cyc, arr2d_small[0][1].result, expected_small[0][1]);
        $stop;
      end
      if (arr2d_small[1][0].result !== expected_small[1][0]) begin
        $display("FAIL cyc=%0d: arr2d_small[1][0].result=%h expected %h",
                 cyc, arr2d_small[1][0].result, expected_small[1][0]);
        $stop;
      end
      if (arr2d_small[1][1].result !== expected_small[1][1]) begin
        $display("FAIL cyc=%0d: arr2d_small[1][1].result=%h expected %h",
                 cyc, arr2d_small[1][1].result, expected_small[1][1]);
        $stop;
      end

      // Check single-element 2-D array
      if (arr2d_one[0][0].result !== expected_one) begin
        $display("FAIL cyc=%0d: arr2d_one[0][0].result=%h expected %h",
                 cyc, arr2d_one[0][0].result, expected_one);
        $stop;
      end
    end

    if (cyc == 20) begin
      $write("*-* All Finished *-*\n");
      $finish;
    end
  end
endmodule
