add wave -group "TB Signals" tb_threshold_compress/*
add wave -group "MUT"        tb_threshold_compress/i_mut/*
add wave -group "MUT"        tb_threshold_compress/i_mut/genblk1[0]/i_ternary_encoder/encoder_i
add wave -group "MUT"        tb_threshold_compress/i_mut/genblk1[0]/i_ternary_encoder/encoder_o

configure wave -namecolwidth  250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns
