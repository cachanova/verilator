# 2-D Interface Array Support - Progress Document

## Goal

Add support for 2-dimensional interface arrays in Verilator, allowing syntax like:

```systemverilog
simple_if arr2d[1:0][1:0]();  // 2x2 array of interfaces

module handler(simple_if iface);
  // ...
endmodule

module t;
  simple_if arr2d[1:0]();
  handler h00(.iface(arr2d[0][0]));
  // ...
  initial begin
    arr2d[0][0].data = 8'hAA;
    if (arr2d[0][0].result == 8'h55) ...
  end
endmodule
```

## Related Issues/PRs

- Upstream Issue: https://github.com/verilator/verilator/issues/5066
- Related PR: https://github.com/verilator/verilator/pull/6986 (nested interface as port)
- Related PR: https://github.com/verilator/verilator/pull/6998 (fix for -fno-inline)

## Files Modified

### 1. `src/V3ParseGrammar.cpp` - DONE ✓

Removed the restriction that blocked multi-dimensional interface arrays.

**Location:** `scrubRange()` function

**Change:** Removed the block that issued `E_UNSUPPORTED` for multidimensional instances.

### 2. `src/V3LinkDot.cpp` - DONE ✓

Modified `visit(AstSelBit*)` to handle nested SelBit nodes for 2-D array access.

**Key insight:** For `arr2d[0][1].data`, the parser creates nested SelBit nodes. When V3LinkDot processes these, it needs to create a single `AstCellArrayRef` with MULTIPLE indices in its `selp` list (which is defined as `List[AstNodeExpr]`).

**Change:** When processing an outer SelBit and finding that `fromp` is already a CellArrayRef (from processing an inner dimension), we now ADD the new index to the existing CellArrayRef's selp list instead of creating a new CellArrayRef.

```cpp
if (innerCellArrayRefp) {
    // Multi-dimensional array: add this dimension's index to existing CellArrayRef
    innerCellArrayRefp->addSelp(exprp);
    innerCellArrayRefp->unlinkFrBack();
    nodep->replaceWith(innerCellArrayRefp);
    // ...
} else {
    // First dimension: create new CellArrayRef
    // ...
}
```

**Result:** The CellArrayRef now has multiple CONST children representing each dimension's index:
```
CELLARRAYREF arr2d
  CONST 0   (first dimension index)
  CONST 0   (second dimension index)
```

### 3. `src/V3Param.cpp` - DONE ✓

Modified `visit(AstCellArrayRef*)` to handle CellArrayRef nodes with multiple selp entries.

**Key insight:** The VARXREF's dotted name contains multiple `__BRA__??__KET__` placeholders (one per dimension). Each selp entry should replace one placeholder.

**Change:** Instead of handling a single selp, we now iterate through all selp entries and replace each `__BRA__??__KET__` placeholder in order.

**Result:** After V3Param, the VARXREF dotted name is correctly transformed:
- Before: `arr2d__BRA__??__KET____BRA__??__KET__`
- After: `arr2d__BRA__0__KET____BRA__0__KET__`

### 4. `src/V3Inst.cpp` - NEEDS WORK

The multi-dimensional expansion logic was implemented in a previous session but may have issues.

**Current state:** The VAR for the interface array is `arr2d__Viftop` (single VAR for the whole array). For 2-D arrays to work, V3Inst needs to expand this into individual VARs like:
- `arr2d__BRA__0__KET____BRA__0__KET____Viftop`
- `arr2d__BRA__0__KET____BRA__1__KET____Viftop`
- `arr2d__BRA__1__KET____BRA__0__KET____Viftop`
- `arr2d__BRA__1__KET____BRA__1__KET____Viftop`

## Current Error

```
%Error: /tmp/test_2d_simple.v:20:17: Can't find definition of 'arr2d[0][0]'
   20 |     arr2d[0][0].data = 8'hAA;
      |                 ^~~~
```

This error occurs in the second linkdot pass (after V3Param). The VARXREF is looking for `arr2d__BRA__0__KET____BRA__0__KET__` but no such VAR exists because V3Inst hasn't expanded the 2-D array into individual elements.

## What's Working

1. **Parsing:** Multi-dimensional interface array syntax is now accepted
2. **V3LinkDot:** Creates proper CellArrayRef with multiple indices
3. **V3Param:** Correctly replaces all `??` placeholders in the dotted name

## What's Not Working

1. **V3Inst:** Not expanding 2-D interface arrays into individual VARs/CELLs

## Test File

The test file is at `/tmp/test_2d_simple.v`:

```systemverilog
interface simple_if;
  logic [7:0] data;
  logic [7:0] result;
endinterface

module handler(simple_if iface);
  assign iface.result = iface.data ^ 8'hFF;
endmodule

module t;
  simple_if arr2d[1:0]();

  handler h00(.iface(arr2d[0][0]));
  handler h01(.iface(arr2d[0][1]));

  initial begin
    arr2d[0][0].data = 8'hAA;
    #10;
    if (arr2d[0][0].result == 8'h55)
      $display("*-* All Finished *-*");
    $finish;
  end
endmodule
```

Note: This test currently uses `arr2d[1:0]` (1-D) but accesses it as 2-D. For proper 2-D testing, change to `arr2d[1:0][1:0]`.

## Next Steps

### 1. Debug V3Inst Multi-Dimensional Expansion

Check the `visit(AstVar*)` and `visit(AstCell*)` functions in V3Inst.cpp. The multi-dimensional helper functions were added in a previous session:

- Look for `collectArrayDimensions()` or similar helper
- Verify nested loop expansion is creating the right names
- Check if expansion runs at the right time (before V3Param's second linkdot pass)

### 2. Verify Pass Order

Understand when V3Inst runs relative to other passes:
- V3Inst should expand interface arrays BEFORE V3Param
- The expanded VARs should exist when the second linkdot pass runs

### 3. Check Naming Convention

Ensure V3Inst generates names matching what V3LinkDot/V3Param expect:
- Format: `arr2d__BRA__<outer>__KET____BRA__<inner>__KET__`
- Order: outer dimension first, inner dimension second

### 4. Add Debug Output

Add UINFO statements in V3Inst to trace what's happening during expansion:
```cpp
UINFO(4, "Expanding 2-D interface array: " << varName << endl);
UINFO(4, "  Creating expanded VAR: " << expandedName << endl);
```

## Key Files to Review

1. `src/V3Inst.cpp` - Interface array expansion (lines ~192-313)
2. `src/V3LinkDot.cpp` - SelBit handling (lines ~5003-5051)
3. `src/V3Param.cpp` - CellArrayRef handling (lines ~2150-2231)

## Attempted Approaches That Didn't Work

### Sibling CellArrayRef Approach

Initially tried creating multiple CellArrayRef nodes as siblings. This failed because:
- `unlinkFrBack()` on a node with siblings leaves the siblings behind (they become the new op pointer target)
- When UNLINKEDREF uses `m_ds.m_unlinkedScopep->unlinkFrBack()`, only the first CellArrayRef was passed

### Solution That Works

Using the single CellArrayRef with multiple selp entries works because:
- `selp` is defined as `List[AstNodeExpr]`, designed to hold multiple nodes
- All indices stay together in one node
- V3Param can iterate through all selp entries to replace all placeholders

## Git Branch

Current branch: `fix-nested-ifs-port-arrays`

This branch contains:
- Original fixes from PRs #6986 and #6998 for nested interface ports
- Our work-in-progress for 2-D interface array support
