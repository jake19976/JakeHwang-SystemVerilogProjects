onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and reset}
add wave -noupdate /mkMultBuff_tb/clk
add wave -noupdate /mkMultBuff_tb/RST_N
add wave -noupdate -divider {Multiply handshake and operands}
add wave -noupdate /mkMultBuff_tb/EN_mult
add wave -noupdate /mkMultBuff_tb/RDY_mult
add wave -noupdate -radix decimal /mkMultBuff_tb/mult_input0
add wave -noupdate -radix decimal /mkMultBuff_tb/mult_input1
add wave -noupdate -divider {Memory writes}
add wave -noupdate /mkMultBuff_tb/EN_writeMem
add wave -noupdate -radix unsigned /mkMultBuff_tb/writeMem_addr
add wave -noupdate -radix hexadecimal /mkMultBuff_tb/writeMem_val
add wave -noupdate -divider {Read handshake and memory requests}
add wave -noupdate /mkMultBuff_tb/EN_blockRead
add wave -noupdate /mkMultBuff_tb/RDY_blockRead
add wave -noupdate /mkMultBuff_tb/EN_readMem
add wave -noupdate -radix unsigned /mkMultBuff_tb/readMem_addr
add wave -noupdate -divider {Read responses}
add wave -noupdate /mkMultBuff_tb/VALID_memVal
add wave -noupdate -radix hexadecimal /mkMultBuff_tb/readMem_val
add wave -noupdate -radix hexadecimal /mkMultBuff_tb/memVal_data
add wave -noupdate -divider {RTL pipeline and controller}
add wave -noupdate -radix binary /mkMultBuff_tb/DUT/pipeline_valid
add wave -noupdate -radix unsigned /mkMultBuff_tb/DUT/accepted_count
add wave -noupdate -radix unsigned /mkMultBuff_tb/DUT/landed_count
add wave -noupdate -radix unsigned /mkMultBuff_tb/DUT/read_ptr
add wave -noupdate /mkMultBuff_tb/DUT/draining
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {4979626 ps}
