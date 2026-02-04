// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// SPDX-FileCopyrightText: 2026 Leela Pakanati
// SPDX-License-Identifier: CC0-1.0
//
// Test case for issue #5581: Nested interface modport access
// Access modport of an interface instance nested inside another interface

interface l5_if (input clk);
  logic sig5;
  modport mp5(output sig5);

  assign sig5 = 1'b1;
endinterface

interface l4_if (input clk);
  l5_if l5(clk);
endinterface

interface l3_if (input clk);
  logic sig1;
  l4_if l4(clk);
  modport mp1(output sig1);
endinterface

interface l2_if #(parameter int ID = 0) (input clk);
  logic [3:0] tag;
  l3_if l3(clk);

  assign tag = ID[3:0];
endinterface

interface l1_if (input clk);
  logic data;
  logic valid;
  l2_if l2(clk);

  modport master(output data, output valid);
  modport slave(input data, input valid);
endinterface

interface l0_if (input clk);
  l1_if l1(clk);
  l2_if #(.ID(1)) l2a(clk);
  l2_if #(.ID(2)) l2b(clk);
  logic enable;
endinterface

module producer (
  l1_if.master port
);
  always_comb begin
    port.data = 1'b1;
    port.valid = 1'b1;
  end
endmodule

module consumer (
  l1_if.slave port,
  output logic received_data,
  output logic received_valid
);
  always_comb begin
    received_data = port.data;
    received_valid = port.valid;
  end
endmodule

// Test with multiple levels of nesting (l0 -> l1 -> l2 -> l3)
module l3_driver #(
  parameter logic VAL = 1'b1
) (
  l3_if.mp1 port
);
  always_comb port.sig1 = VAL;
endmodule

module t (/*AUTOARG*/
  // Inputs
  clk
);
  input clk;

  // Test 1: Simple nested interface modport access
  // Producer drives master, consumer reads slave
  l0_if l0_simple(clk);
  logic cons1_data, cons1_valid;
  producer prod1(.port(l0_simple.l1.master));
  consumer cons1(.port(l0_simple.l1.slave), .received_data(cons1_data), .received_valid(cons1_valid));

  // Test 2: Deep nesting (l0 -> l1 -> l2 -> l3 -> l4 -> l5)
  l0_if l0_deep(clk);
  l3_driver #(.VAL(1'b1)) l3_drv(.port(l0_deep.l1.l2.l3.mp1));

  integer cyc = 0;
  always_ff @(posedge clk) begin
    cyc <= cyc + 1;

    // Verify Test 1: Producer wrote data, consumer received it
    if (cons1_data !== 1'b1) begin
      $display("Error: cons1_data = %b, expected 1", cons1_data);
      $stop;
    end
    if (cons1_valid !== 1'b1) begin
      $display("Error: cons1_valid = %b, expected 1", cons1_valid);
      $stop;
    end

    // Verify Test 2: Deep nesting works
    if (l0_deep.l2a.tag !== 4'd1) begin
      $display("Error: l0_deep.l2a.tag = %0d, expected 1", l0_deep.l2a.tag);
      $stop;
    end
    if (l0_deep.l2b.tag !== 4'd2) begin
      $display("Error: l0_deep.l2b.tag = %0d, expected 2", l0_deep.l2b.tag);
      $stop;
    end
    if (l0_deep.l1.l2.l3.sig1 !== 1'b1) begin
      $display("Error: l0_deep.l1.l2.l3.sig1 = %b, expected 1", l0_deep.l1.l2.l3.sig1);
      $stop;
    end
    if (l0_deep.l1.l2.l3.l4.l5.sig5 !== 1'b1) begin
      $display("Error: l0_deep.l1.l2.l3.l4.l5.sig5 = %b, expected 1",
               l0_deep.l1.l2.l3.l4.l5.sig5);
      $stop;
    end

    if (cyc == 2) begin
      $write("*-* All Finished *-*\n");
      $finish;
    end
  end

endmodule
