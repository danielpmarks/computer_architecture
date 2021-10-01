transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set mp3_path [pwd]

vlog -reportprogress 300 -work work $mp3_path/../../hdl/rv32i_mux_types.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/rv32i_types.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/array.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/bus_adapter.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/cache.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/cache_control.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/cache_datapath.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/data_array.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cacheline_adaptor.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cpu_golden.vp
vlog -reportprogress 300 -work work $mp3_path/../../hdl/mp3.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/cache_monitor_itf.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/param_memory.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/rvfimon.v
vlog -reportprogress 300 -work work $mp3_path/../../hvl/shadow_memory.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/source_tb.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/tb_itf.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/top.sv

vsim -t 1ps -gui -L rtl_work -L work mp3_tb

add wave *
view structure
view signals
run -all
