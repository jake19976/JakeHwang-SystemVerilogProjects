# ELEC402 Project 2: GUI waveform capture using the existing checker files.
# Launch vsim from the repository root, then use one of:
#   do view_waveforms.do rtl 400
#   do view_waveforms.do rtl 800
#   do view_waveforms.do sdf 400
#   do view_waveforms.do sdf 800
# This script only compiles/simulates and writes waveform files/layouts.
# Existing synthesis outputs and sources are not modified.

if {![info exists 1] || ![info exists 2]} {
    error "Usage: do view_waveforms.do rtl|sdf 400|800"
}
set wave_mode [string tolower $1]
set wave_tag $2
if {$wave_mode ni {rtl sdf} || $wave_tag ni {400 800}} {
    error "Usage: do view_waveforms.do rtl|sdf 400|800"
}
if {![file exists bob.py]} {
    error "Start Questa from the repository root containing bob.py. Current directory: [pwd]"
}
file mkdir submission/outputs
set wave_starter [list starter/rtl/memory_wrapper_2port.sv starter/rtl/registerArray.sv]
set wave_wlf submission/outputs/${wave_mode}_${wave_tag}_wave.wlf
set wave_layout submission/outputs/${wave_mode}_${wave_tag}_wave_layout.do

if {$wave_mode eq "rtl"} {
    set wave_top mkMultBuff_tb
    set wave_checker submission/testbench/rtl_checker.sv
    set wave_sources [glob submission/rtl_${wave_tag}/*.sv]
    vlog -sv {*}$wave_starter {*}$wave_sources $wave_checker
    if {$wave_tag eq "400"} {set wave_half 1.25} else {set wave_half 0.625}
    vsim -voptargs=+acc -wlf $wave_wlf -gCLK_HALF_NS=$wave_half work.$wave_top
} else {
    set wave_top mkMultBuff_sdf_checker_${wave_tag}
    set wave_checker submission/testbench/sdf_checker_${wave_tag}.sv
    set wave_netlist submission/outputs/mkMultBuff_${wave_tag}_map.sv
    set wave_sdf submission/outputs/mkMultBuff_${wave_tag}_map.sdf
    set wave_library /ubc/ece/data/cmc2/kits/GPDK45/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v
    foreach wave_required [list $wave_library $wave_netlist $wave_sdf $wave_checker] {
        if {![file exists $wave_required]} {error "Missing required file: $wave_required"}
    }
    vlog -sv $wave_library {*}$wave_starter $wave_netlist $wave_checker
    vsim -voptargs=+acc -wlf $wave_wlf +sdf_file=$wave_sdf work.$wave_top
}

# Keep the simulator open at $finish and record signals before running.
onfinish stop
view wave
set wave_root sim:/$wave_top
log -r /$wave_top/*
add wave -divider "Clock and reset"
add wave $wave_root/clk $wave_root/RST_N
add wave -divider "Multiply handshake and operands"
add wave $wave_root/EN_mult $wave_root/RDY_mult
add wave -radix decimal $wave_root/mult_input0 $wave_root/mult_input1
add wave -divider "Memory writes"
add wave $wave_root/EN_writeMem
add wave -radix unsigned $wave_root/writeMem_addr
add wave -radix hexadecimal $wave_root/writeMem_val
add wave -divider "Read handshake and memory requests"
add wave $wave_root/EN_blockRead $wave_root/RDY_blockRead $wave_root/EN_readMem
add wave -radix unsigned $wave_root/readMem_addr
add wave -divider "Read responses"
add wave $wave_root/VALID_memVal
add wave -radix hexadecimal $wave_root/readMem_val $wave_root/memVal_data
if {$wave_mode eq "rtl"} {
    add wave -divider "RTL pipeline and controller"
    add wave -radix binary $wave_root/DUT/pipeline_valid
    add wave -radix unsigned $wave_root/DUT/accepted_count $wave_root/DUT/landed_count
    add wave -radix unsigned $wave_root/DUT/read_ptr
    add wave $wave_root/DUT/draining
}

run -all
wave zoom full
log -flush
write format wave $wave_layout
puts "Waveform data: $wave_wlf"
puts "Wave layout:   $wave_layout"
puts "Check the transcript for ALL PASS and SDF annotation success (for SDF runs)."
puts "Zoom into a short interval before taking a report screenshot."
