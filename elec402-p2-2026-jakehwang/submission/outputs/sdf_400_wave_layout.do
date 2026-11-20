onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and reset}
add wave -noupdate /mkMultBuff_sdf_checker_400/clk
add wave -noupdate /mkMultBuff_sdf_checker_400/RST_N
add wave -noupdate -divider {Multiply handshake and operands}
add wave -noupdate /mkMultBuff_sdf_checker_400/EN_mult
add wave -noupdate /mkMultBuff_sdf_checker_400/RDY_mult
add wave -noupdate -radix decimal /mkMultBuff_sdf_checker_400/mult_input0
add wave -noupdate -radix decimal /mkMultBuff_sdf_checker_400/mult_input1
add wave -noupdate -divider {Memory writes}
add wave -noupdate /mkMultBuff_sdf_checker_400/EN_writeMem
add wave -noupdate -radix unsigned /mkMultBuff_sdf_checker_400/writeMem_addr
add wave -noupdate -radix hexadecimal /mkMultBuff_sdf_checker_400/writeMem_val
add wave -noupdate -divider {Read handshake and memory requests}
add wave -noupdate /mkMultBuff_sdf_checker_400/EN_blockRead
add wave -noupdate /mkMultBuff_sdf_checker_400/RDY_blockRead
add wave -noupdate /mkMultBuff_sdf_checker_400/EN_readMem
add wave -noupdate -radix unsigned /mkMultBuff_sdf_checker_400/readMem_addr
add wave -noupdate -divider {Read responses}
add wave -noupdate /mkMultBuff_sdf_checker_400/VALID_memVal
add wave -noupdate -radix hexadecimal /mkMultBuff_sdf_checker_400/readMem_val
add wave -noupdate -radix hexadecimal /mkMultBuff_sdf_checker_400/memVal_data
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
WaveRestoreZoom {0 ps} {2609251 ps}
