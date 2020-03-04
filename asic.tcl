# List all current designs
set this_design [ list_designs ]

# If there are existing designs reset/remove them
if { $this_design != 0 } {
  # To reset the earlier designs
  reset_design
  remove_design -designs
}

if { ! [ info exists top_design ] } {
   set top_design asic_fifo
}

lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_hvt/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_rvt/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_lvt/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/io_std/db_nldm"
lappend search_path "/pkgs/synopsys/2016/libs/SAED32_EDK/lib/sram/db_nldm"

set synthetic_library dw_foundation.sldb

# Changed to only be the slow corner libraries
#set target_library "saed32hvt_ss0p75v125c.db saed32lvt_ss0p75v125c.db saed32rvt_ss0p75v125c.db"
# enable the lvt and rvt library for now at the slow corner
set target_library "saed32lvt_ss0p75v125c.db saed32rvt_ss0p75v125c.db"

# Changed to only be the slow corner libraries
set link_library [join "$target_library * saed32hvt_ss0p75v125c.db saed32io_wb_ss0p95v125c_2p25v.db saed32sram_ss0p95v125c.db dw_foundation.sldb" ]
#set tlu_dir /pkgs/synopsys/2016/libs/SAED32_EDK/tech/star_rcxt/
#set_tlu_plus_files  -max_tluplus $tlu_dir/saed32nm_1p9m_Cmax.tluplus  \
#	            -min_tluplus $tlu_dir/saed32nm_1p9m_Cmin.tluplus  \
#		    -tech2itf_map  $tlu_dir/saed32nm_tf_itf_tluplus.map

# Remove any existing MW direotory
#exec rm -rf ${top_design}.mw
#creating milky way library and linking physical information of the cell 
#set mw_lib ""
#lappend mw_lib /pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_lvt/milkyway/saed32nm_lvt_1p9m
#lappend mw_lib /pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_rvt/milkyway/saed32nm_rvt_1p9m
#lappend mw_lib /pkgs/synopsys/2016/libs/SAED32_EDK/lib/stdcell_hvt/milkyway/saed32nm_hvt_1p9m
#lappend mw_lib /pkgs/synopsys/2016/libs/SAED32_EDK/lib/io_std/milkyway/saed32_io_wb
#lappend mw_lib /pkgs/synopsys/2016/libs/SAED32_EDK/lib/sram/milkyway/SRAM32NM

#set tf_dir "/pkgs/synopsys/2016/libs/SAED32_EDK/tech/milkyway/"
#set tlu_dir /pkgs/synopsys/2016/libs/SAED32_EDK/tech/star_rcxt/
#set_tlu_plus_files  -max_tluplus $tlu_dir/saed32nm_1p9m_Cmax.tluplus  \
#                    -min_tluplus $tlu_dir/saed32nm_1p9m_Cmin.tluplus  \
#                    -tech2itf_map  $tlu_dir/saed32nm_tf_itf_tluplus.map
#create_mw_lib ${top_design}.mw -technology $tf_dir/saed32nm_1p9m_mw.tf  -mw_reference_library $mw_lib -open

#read_ddc ../outputs/${top_design}.ddc
# Analyzing the current FIFO design
analyze -format sverilog ../rtl/${top_design}.sv


# Elaborate the FIFO design
elaborate ${top_design} 

if [ info exists add_ios ] 
{
   source -echo -verbose ../scripts/add_ios.tcl
}
#extract_physical_constraints ../../apr/outputs/${top_design}.floorplan.def

source -echo -verbose ../../constraints/${top_design}.sdc

# Constrain the overall data path of the design.
# 50% or so of the clock period is good.
set_max_transition 0.5 [current_design ]

#set_wire_load_mode enclosed
#set_wire_load_model -name 8000


#reading physical information 
# with below commented, it will make up a floorplan of reasonable size and utilization.  
# Leave below commented for now.

uniquify

#set compile_enable_constant_propagation_with_no_boundary_opt false
#set compile_enhanced_resource_sharing true
#set set_dp_smartgen_options ??
#set_multi_vth_constraint
# Other options or variables??

# try ungroup command on a hierarchy?

#compile map the sequential cell exactly as in the rtl
# compile -scan
# options for compile?  like -exact_map -ungroup?

compile_ultra  -scan
# compile_ultra -scan -gate_clock -no_boundary_optimization -no_autoungroup 
# Other options?

#Insert DFT 
#set_dft_signal -view existing_dft -type ScanClock -port clk -timing [list 45 55]
# if there are any resets or generated clocks, they should have a mux and be controllable by ports during test
#set_dft_signal -port test_rb_ctrl -active_state 1 -view existing -type constant
# This is for the te pin for test enable on a clock gating cell inserted by power compiler
#set_dft_signal -port scan_te -active_state 1 -view existing -type constant
#set_dft_signal -port test_mode -active_state 1 -view existing -type constant
#create_test_protocol -infer_clock -infer_asynch
#dft_drc -pre_dft
#preview_dft
#insert_dft
#dft_drc

#Compile Incr done after DFT insertion
#compile_ultra -scan -incremental

echo check_timing command
check_timing -include {no_driving_cell no_input_delay partial_input_delay unconstrained_endpoints }
echo report_qor command
report_qor
report_power
echo report_constraint command (PWR-6, PWR-414, PWR-415 Warnings are ok)
report_constraint -all_violators -max_delay -max_cap -max_tran -max_fan
echo do a report_timing command on any violators to get details 
echo or do a report_constraint -all_violators -verbose

# For information on get_timing_path make sure you check the man page for it.
# There are lots of examples on how to use it with example TCL code there.
 
# set bad_paths [ get_timing_path -group rclk -max_paths 10 -nworst 10 ] 
# set related_points [ get_attribute $bad_paths points ]
# set related_pins [ get_attribute $related_points object ]
# set one_pin [ index_collectino $related_pins 1 ]
# get_attribute $one_pin driver_fall_transition_max
# get_attribute $one_pin worst_fall_slack
# get_attribute [get_cell -of_obj $one_pin ] ref_name
# check if the ref_name is a buffer or inverter for the logic level filtering
# check if the ref_name has rvt or lvt in the name for power improvement swapping
# remember the foreach_in_collection command to rotate through all the elements.

#foreach_in_collection a_path $path {
#echo [get_attribute $a_path slack ] 
#foreach_in_collection a_point [ get_attribute $a_path points ] {
# set the_pin [get_attribute $a_point  object ]
# echo  [get_attribute $the_pin full_name ]
# echo [ get_attribute [get_cell -of_obj $the_pin ] full_name ]
# echo [ get_attribute [get_cell -of_obj $the_pin ] ref_name ]
#}                                                                                                                  }
#}


#dc_shell-topo> sizeof_collection [ get_timing_paths -slack_lesser_than 0 ]
#4
#dc_shell-topo> sizeof_collection [ get_timing_paths -slack_lesser_than 0 -max_paths 1000 ]
#1125
#dc_shell-topo> sizeof_collection [ get_timing_paths -slack_lesser_than 0 -max_paths 1500 ]
#1125


#get_attribute  fifomem/mem_reg[62][6]/Q worst_slack
#size_cell sync_r2w/wq1_rptr_reg[5] SDFFASX1_RVT

# for looking for LVT to RVT swaps.
#report_timing  -slack_greater_than 0.05
#get_timing_path -slack_greater_than 0.05

set stage dc
report_qor > ../reports/${top_design}.$stage.qor.rpt
report_constraint -all_viol > ../reports/${top_design}.$stage.constraint.rpt
report_timing -delay max -input -tran -cross -sig 4 -derate -net -cap  -max_path 10000 > ../reports/${top_design}.$stage.timing.max.rpt
check_timing  > ../reports/${top_design}.$stage.check_timing.rpt
check_design > ../reports/${top_design}.$stage.check_design.rpt
check_mv_design  > ../reports/${top_design}.$stage.mvrc.rpt

write -hier -format verilog -output ../outputs/${top_design}.$stage.vg
write -hier -format ddc -output ../outputs/${top_design}.$stage.ddc

