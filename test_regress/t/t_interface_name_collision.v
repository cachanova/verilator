// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Leela Pakanati
// SPDX-License-Identifier: CC0-1.0

// Test for issue #5120: Interface name collision after inlining
// When a parent module has an interface port and a child module has
// a local interface instance with the same name, Verilator should
// correctly distinguish between them after inlining.

interface MYIF;
  logic tvalid;
  modport master(output tvalid);
  modport slave(input tvalid);
endinterface

module t (/*AUTOARG*/
  // Inputs
  clk
);
  input clk;
  integer cyc = 0;

  // Test 1: Original collision test
  MYIF myif();
  parent p(.myif(myif));

  // Test 2: 3+ levels of hierarchy
  DEEPIF deepif();
  level1_parent lp(.deepif(deepif));

  // Test 3: Multiple sibling children with same-named local interfaces
  MULTIIF multi();
  multi_parent mp(.multi(multi));

  always @(posedge clk) begin
    cyc <= cyc + 1;
    if (cyc == 5) begin
      // Test 1: Check that the parent's port connection works
      // myif.tvalid should be 0 (driven by nothing), not 1 (from child's local)
      if (myif.tvalid !== 1'b0) begin
        $display("Error: Test 1 failed - myif.tvalid = %b, expected 0", myif.tvalid);
        $stop;
      end

      // Test 2: Check that deep hierarchy port is undriven (0), not 0xFF from level3_child
      if (deepif.data !== 8'h00) begin
        $display("Error: Test 2 failed - deepif.data = %h, expected 00", deepif.data);
        $stop;
      end

      // Test 3: Check that sibling children's local interfaces don't collide
      // multi.val should be 0 (undriven), not 1 from child_a or child_b local interfaces
      if (multi.val !== 1'b0) begin
        $display("Error: Test 3 failed - multi.val = %b, expected 0", multi.val);
        $stop;
      end

      $write("*-* All Finished *-*\n");
      $finish;
    end
  end
endmodule

module parent(MYIF.slave myif);
  child c();
endmodule

// Child module has a local interface instance also named 'myif'
// This should NOT collide with parent's interface port
module child;
  MYIF myif();  // Local interface instance with same name
  assign myif.tvalid = 1'b1;  // Should assign to local interface, not parent's port
endmodule

// Test 2: 3+ levels of module hierarchy
// Tests that inlining fix works recursively through multiple parent-child relationships
interface DEEPIF;
  logic [7:0] data;
  modport master(output data);
  modport slave(input data);
endinterface

module level1_parent(DEEPIF.slave deepif);
  level2_middle m(.deepif(deepif));
endmodule

module level2_middle(DEEPIF.slave deepif);
  level3_child c();
endmodule

// Level 3 child has local interface with same name 'deepif'
module level3_child;
  DEEPIF deepif();
  assign deepif.data = 8'hFF;  // Should write to local, not parent's port
endmodule

// Test 3: Multiple sibling children with same-named local interfaces
// Tests that multiple inlined modules with same-named local interfaces
// don't collide with each other or with parent's port
interface MULTIIF;
  logic val;
  modport master(output val);
  modport slave(input val);
endinterface

module multi_parent(MULTIIF.slave multi);
  // Two sibling children, each with local interface named 'multi'
  multi_child_a ca();
  multi_child_b cb();
endmodule

module multi_child_a;
  MULTIIF multi();  // Local 'multi' - should not collide with parent's port
  assign multi.val = 1'b1;
endmodule

module multi_child_b;
  MULTIIF multi();  // Another local 'multi' - should not collide with sibling or parent
  assign multi.val = 1'b1;
endmodule
