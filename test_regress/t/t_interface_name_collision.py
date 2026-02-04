#!/usr/bin/env python3
# DESCRIPTION: Verilator: Verilog Test module
#
# This file ONLY is placed under the Creative Commons Public Domain.
# SPDX-FileCopyrightText: 2026 Wilson Snyder
# SPDX-License-Identifier: CC0-1.0

import vltest_bootstrap

test.scenarios('simulator')
test.top_filename = "t/t_interface_name_collision.v"

test.compile(verilator_flags2=["--trace"])

test.execute()

test.passes()
