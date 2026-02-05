// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2025 Leela Pakanati
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkh(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0x exp=%0x (%s !== %s)\n", `__FILE__,`__LINE__, (gotv), (expv), `"gotv`", `"expv`"); `stop; end while(0);
// verilog_format: on

// =============================================================================
// Basic modport expression tests
// =============================================================================

interface my_if #(parameter WIDTH = 1);
  logic [WIDTH-1:0] sig_a, sig_b, sig_c, sig_d;
  logic [WIDTH-1:0] sig_e, sig_f;
  // Multiple expressions same direction
  logic [WIDTH-1:0] m1, m2, m3;

  modport mp1(input .a(sig_a), output .b(sig_b));
  modport mp2(input .a(sig_c), output .b(sig_d));
  // Mixed regular and expression items
  modport mp3(input sig_e, output .f(sig_f));
  // Multiple expressions with same direction
  modport mp4(input .in1(m1), input .in2(m2), output .out(m3));
endinterface

module mod1 (
    my_if.mp1 i
);
  assign i.b = i.a;
endmodule

module mod2 (
    my_if.mp2 i
);
  assign i.b = i.a;
endmodule

module mod3 (
    my_if.mp3 i
);
  assign i.f = i.sig_e;  // sig_e is regular, f is expression
endmodule

module mod4 (
    my_if.mp4 i
);
  assign i.out = i.in1 ^ i.in2;
endmodule

// =============================================================================
// Nested interface modport expression tests (2-level)
// =============================================================================

interface base_reg_if;
  logic [7:0] wr;
  logic [7:0] rd;
  modport host(output wr, input rd);
  modport dev(input wr, output rd);
endinterface

interface example_reg_if;
  logic [15:0] wr;
  logic [15:0] rd;
  modport host(output wr, input rd);
  modport dev(input wr, output rd);
endinterface

interface app_reg_if;
  base_reg_if base();
  example_reg_if example();

  // Use modport expressions to expose nested interface signals
  modport host(
    output .base_wr(base.wr), input .base_rd(base.rd),
    output .example_wr(example.wr), input .example_rd(example.rd)
  );
  modport dev(
    input .base_wr(base.wr), output .base_rd(base.rd),
    input .example_wr(example.wr), output .example_rd(example.rd)
  );
endinterface

module app_consumer (
    app_reg_if.dev i_app_regs
);
  // Access through modport expression virtual ports
  assign i_app_regs.base_rd = i_app_regs.base_wr + 8'h1;
  assign i_app_regs.example_rd = i_app_regs.example_wr + 16'h1;
endmodule

// =============================================================================
// Deep nesting test (3 levels)
// =============================================================================

interface inner_if;
  logic [7:0] data;
  modport producer(output data);
  modport consumer(input data);
endinterface

interface middle_if;
  inner_if inner();
endinterface

interface outer_if;
  middle_if middle();

  // 3-level deep modport expression
  modport mp(
    output .deep_out(middle.inner.data),
    input .deep_in(middle.inner.data)
  );
endinterface

module deep_consumer(outer_if.mp port);
  assign port.deep_out = 8'hDE;
endmodule

// =============================================================================
// Top module
// =============================================================================

module top;
  // Basic tests
  my_if #(.WIDTH(8)) myIf ();
  assign myIf.sig_a = 8'h42, myIf.sig_c = 8'hAB;
  assign myIf.sig_e = 8'hCD;
  assign myIf.m1 = 8'hF0, myIf.m2 = 8'h0F;

  mod1 mod1i (myIf.mp1);
  mod2 mod2i (myIf.mp2);
  mod3 mod3i (myIf.mp3);
  mod4 mod4i (myIf.mp4);

  // Nested interface tests
  app_reg_if app_regs();
  outer_if outer();

  app_consumer m_app(.i_app_regs(app_regs));
  deep_consumer m_deep(.port(outer));

  initial begin
    // Set up nested interface inputs
    app_regs.base.wr = 8'hAB;
    app_regs.example.wr = 16'hCDEF;

    #1;
    // Basic modport expression checks
    `checkh(myIf.sig_b, 8'h42); // mp1: b = a
    `checkh(myIf.sig_d, 8'hAB); // mp2: b = a
    `checkh(myIf.sig_f, 8'hCD); // mp3: f = sig_e
    `checkh(myIf.m3, 8'hFF);    // mp4: out = in1 ^ in2

    // Nested interface checks (2-level)
    `checkh(app_regs.base.rd, 8'hAC);
    `checkh(app_regs.example.rd, 16'hCDF0);

    // Deep nesting check (3-level)
    `checkh(outer.middle.inner.data, 8'hDE);

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
