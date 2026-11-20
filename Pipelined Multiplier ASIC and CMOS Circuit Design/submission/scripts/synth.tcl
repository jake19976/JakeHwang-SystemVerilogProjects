# synth.tcl - Cadence Genus synthesis template, ELEC 402 2026
# Copy to submission/scripts/synth.tcl, fill in every TODO, run with: python3 bob.py synth --run 400 | 800
# Do not rename the output files: bob.py and the SDF / power steps look for them by name.

set TOP_LEVEL    mkMultBuff
set RTL_DIR_400  ./submission/rtl_400
set RTL_DIR_800  ./submission/rtl_800
set STR_DIR      ./starter/rtl
set RPT_DIR      ./submission/syn_reports
set OUT_DIR      ./submission/outputs
set LIB_PATH     /ubc/ece/data/cmc2/kits/GPDK45/gsclib045_all_v4.4/gsclib045/timing

sh mkdir -p $RPT_DIR $OUT_DIR

set_db lib_search_path [concat [get_db lib_search_path] $LIB_PATH]
set_db library "slow_vdd1v0_basicCells.lib"

# tag is the target frequency, 400 or 800. It names the output files.
#### TODO 0: add the other arguments synth_run needs.
proc synth_run {tag rtl_dir synth_period_ps report_period_ps effort retime_enable} {
    global TOP_LEVEL STR_DIR RPT_DIR OUT_DIR

    # Remove the previous target before elaborating another design in an all run.
    if {[llength [get_db designs]] > 0} { delete_obj [get_db designs] }
    if {![file isfile $rtl_dir/mkMultBuff.sv]} {
        error "Missing $rtl_dir/mkMultBuff.sv"
    }
    # Only design RTL is synthesized. The external memory stays in the testbench.
    set RTL_FILES [list]
    foreach f [glob -nocomplain $rtl_dir/*.sv] { lappend RTL_FILES $f }
    foreach f $RTL_FILES { read_hdl -sv $f }
    elaborate $TOP_LEVEL
    set cur [lindex [get_db designs .name] end]
    current_design $cur

    #### TODO 1 completed: clock and input drive.
    set_time_unit -picoseconds
    set_load_unit -femtofarads
    create_clock -name clk -period $synth_period_ps [get_ports clk]
    set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]
    set transition_ps [expr {$report_period_ps / 8.0}]

    # Use a minimum-drive DFF output, never substitute a buffer silently.
    set driver_cell ""
    foreach candidate {DFFXL DFFHQXL DFFX1 DFFHQX1} {
        if {[llength [get_db lib_cells */$candidate]] > 0} {
            set driver_cell $candidate
            break
        }
    }
    if {$driver_cell eq ""} {
        error "No supported minimum-drive DFF in loaded library; inspect get_db lib_cells *DFF*"
    }
    # A subsequent set_input_transition can replace the driving-cell model.
    # Instead specify slew at the external driver's input in this command.
    set_driving_cell -lib_cell $driver_cell -pin Q \
        -input_transition_rise $transition_ps \
        -input_transition_fall $transition_ps $data_inputs
    set_clock_transition $transition_ps [get_clocks clk]
    puts "Target $tag: driver=$driver_cell, driver-input transition=$transition_ps ps"

    #### TODO 2 completed: 4 times NAND2X4 pin A input capacitance.
    set load_pin [get_db lib_pins */NAND2X4/A]
    if {[llength $load_pin] != 1} {
        error "Expected exactly one NAND2X4/A library pin, got: $load_pin"
    }
    # .load is the Genus timing-library input load in fF.
    # Do NOT substitute raw Liberty .capacitance: the server log demonstrated
    # that doing so applied a load 1000 times too small for this library.
    set pin_caps [get_db $load_pin .load]
    puts "Target $tag: NAND2X4/A .load=$pin_caps fF"
    set pin_cap_ff 0.0
    foreach c $pin_caps {
        if {![string is double -strict $c]} { error "Non-numeric pin capacitance: $pin_caps" }
        if {$c > $pin_cap_ff} { set pin_cap_ff $c }
    }
    if {$pin_cap_ff <= 0.0} { error "Invalid NAND2X4/A capacitance: $pin_caps" }
    set output_load_ff [expr {4.0 * $pin_cap_ff}]
    set_load $output_load_ff [all_outputs]
    # Also query the applied database values to expose unit/application errors.
    puts "Target $tag: applied output pin caps=[lsort -unique [get_db [get_db ports -if {.direction == out}] .external_pin_cap]] fF"
    puts "Target $tag: output load=$output_load_ff fF (4x NAND2X4/A)"

    #### TODO 3 completed.
    set_input_delay  -clock [get_clocks clk] -max 0.0 $data_inputs
    set_input_delay  -clock [get_clocks clk] -min 0.0 $data_inputs
    set_output_delay -clock [get_clocks clk] -max 0.0 [all_outputs]
    set_output_delay -clock [get_clocks clk] -min 0.0 [all_outputs]

    # Avoid mux cells whose gate-level model propagates X through both equal
    # data inputs when select is X. A feedback-selected reset mux created a
    # demonstrated startup deadlock on accepted_count[0] with MXI2XL.
    # Remap using other library cells; do not alter/force simulated state.
    set avoided_mux_cells [concat [get_db lib_cells */MXI2*] [get_db lib_cells */MUX2*]]
    if {[llength $avoided_mux_cells] > 0} {
        set_db $avoided_mux_cells .avoid true
        puts "Avoid reset-pessimistic mux family: $avoided_mux_cells"
    }

    #### TODO 4 completed
    set_db syn_generic_effort $effort
    set_db syn_map_effort $effort
    set_db syn_opt_effort $effort
    set_db design:$cur .retime $retime_enable
    syn_generic
    syn_map
    syn_opt
    syn_opt -incremental

    #### TODO 5 completed.
    if {$report_period_ps != $synth_period_ps} {
        delete_obj [get_clocks clk]
        create_clock -name clk -period $report_period_ps [get_ports clk]
    }
    set_clock_transition $transition_ps [get_clocks clk]
    # Reapply delays to the newly created clock object explicitly.
    set_input_delay  -clock [get_clocks clk] -max 0.0 $data_inputs
    set_input_delay  -clock [get_clocks clk] -min 0.0 $data_inputs
    set_output_delay -clock [get_clocks clk] -max 0.0 [all_outputs]
    set_output_delay -clock [get_clocks clk] -min 0.0 [all_outputs]
    check_timing_intent > $RPT_DIR/${TOP_LEVEL}_${tag}_constraints.rpt

    report_area   > $RPT_DIR/${TOP_LEVEL}_${tag}_area.rpt
    report_gates  > $RPT_DIR/${TOP_LEVEL}_${tag}_gates.rpt
    report_timing > $RPT_DIR/${TOP_LEVEL}_${tag}_timing.rpt
    report_power  > $RPT_DIR/${TOP_LEVEL}_${tag}_power.rpt
    report_qor    > $RPT_DIR/${TOP_LEVEL}_${tag}_qor.rpt

    write_hdl -mapped > $OUT_DIR/${TOP_LEVEL}_${tag}_map.sv
    write_sdf         > $OUT_DIR/${TOP_LEVEL}_${tag}_map.sdf
    write_sdc         > $OUT_DIR/${TOP_LEVEL}_${tag}_map.sdc
    write_db -to        $OUT_DIR/${TOP_LEVEL}_synth_${tag}.dat

    puts "done: $tag"
}


if {![info exists RUN_TAG]} { set RUN_TAG "all" }

#### TODO 6: call synth_run for each target. Reports are graded at 2.5 ns (400 MHz) and 1.25 ns (800 MHz).
if {$RUN_TAG ni {400 800 all}} { error "Invalid RUN_TAG: $RUN_TAG" }
if {$RUN_TAG eq "400" || $RUN_TAG eq "all"} {
    # Seek 150 ps of nominal setup margin; grading and SDF checker stay at 2.5 ns.
    synth_run 400 $RTL_DIR_400 2350.0 2500.0 high false
}

if {$RUN_TAG eq "800" || $RUN_TAG eq "all"} {
    synth_run 800 $RTL_DIR_800 1100.0 1250.0 high true
}

puts "synthesis complete - reports in $RPT_DIR"

