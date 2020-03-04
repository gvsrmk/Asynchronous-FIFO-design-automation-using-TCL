#Title:       expr.tcl
#
#	Description: This Tcl procedure generates specific outputs given user input.
# 	INPUTS:
#	 			N 	 - 	Max. Number of paths to be considered for get_timing_path
#	 			SLT  -	Slack Lesser Than value to be given to get_timing_path command
#		 		TRSH -  Max. number of logic levels to look for in each path
#	OUTPUTS:
#               Total_cells  - Total number of cells in each path (Total number of logic levels)
#               N_cells      - Number of times each cell found
#               delay_cell   - Delay of each cell
#	   
#   Options:   	-N -SLT   		Max. Number of paths with SLT value
#				-N -SLT -TRSH   Max. Number of paths with SLT value and threshold value
#
#	Usage:       prompt> source ../scripts/expr.tcl
#					   > my_proc -help
#					   > my_proc -N 5000 -SLT 0 -TRSH 100
#
#	Authors:     Murali Gullapalli

proc my_task_1 args {
   #suppress_message UID-101
   ################################################
   # Parse the user inputs

   set option_N [lindex $args 0] 
   set value_N [lindex $args 1] 
   set option_SLT [lindex $args 2] 
   set value_SLT [lindex $args 3]
   set option_TRSH [lindex $args 4] 
   set value_TRSH [lindex $args 5]


  #--------------------------------------------------
   if {[string match -help* $option_N]} {
       echo " my_proc : This tcl script finds the path with largest number of logic levels Without BUF/INV levels "
	   echo " "
	   echo " usage :   my_task_1 -N <N value> -SLT <SLT value> -TRSH <TRSH value>"
	   echo " "
       echo "-N     : Max. Number of paths to be considered for get_timing_path (0-10000)"
       echo "-SLT   : Slack Lesser Than value to be given to get_timing_path command (0)"
	   echo "-TRSH  : Max. number of logic levels to look for in each path (100)"
       return
       } elseif {[string match -N* $option_N] && [string match -SLT* $option_SLT] && ([string match -TRSH* $option_TRSH]==0)} { 
			# If Threshold is not mentioned [my_proc -N 10000 -SLT 0]
			echo "Threshold not mentioned - inside 1st elseif block"
			  
			 
			set N $value_N
			set SLT $value_SLT 
			

			echo "********************************************************************"
			echo " "
			echo " "
			echo [format " Given N    : %10d " $N]
			echo [format " Given SLT  : %10d " $SLT]
			echo " "
			echo " "
			echo "********************************************************************"
			echo " "
			echo " "
			echo " "
			echo " "
			echo " "
			echo "************************** REPORTING TIMING**************************"
			report_timing 
			echo "***************************REPORT_TIMING COMPLETE*********************************"
			echo " "
			echo " "
			echo " "
			echo " "
			echo " "
			#--------------------------------INTERNAL COUNTER VARIABLES AND ARRAYS-------------------------------------
			array set cell_count_per_path {}
			array set curr_count {}
			set curr_count(0) 0
			set req_index 0
			#----------------------------------------------------------------------------------------------------------
			
			#echo [format "---------------------COMMAND : set all_paths [get_timing_paths -max_paths %10s -slack_lesser_than %10s ] -----------------" $N $SLT]
			
			echo "COMMAND : get_timing_paths \n\n"
			#set all_pths [get_timing_paths -max_paths $N -slack_lesser_than $SLT]
			echo " "
			echo " "
			echo " "
			echo " "
			echo " "
			#echo "-------------- all paths are captured ------------------"
			#echo "-------------- all paths ------------------"

			#echo $all_pths

			# To find the Total Number of cells in the each Timing Path
			#echo "\n\n all_pths printed \n \n"

			for {set i 0} {$i <= $N} {incr i} {
				#set all_paths [get_timing_paths -max_paths $N -slack_lesser_than $SLT]
				#set no_of_paths [llength  $all_paths]
				#echo [format "no of paths are : %d" $no_of_paths]				
				set path [index_collection [get_timing_paths -max_paths $N -slack_lesser_than $SLT] $i]


				#set path [index_collection [get_timing_paths -max_paths 100 -slack_lesser_than 0] 0]
				echo "*******************inside for loop*********************\n\n"
				echo "value of i is "
				echo $i
			    echo "-------------- all paths are captured ------------------"
				set  start_points [get_attribute $path startpoint]
				set  end_points [get_attribute $path endpoint]
				echo "-------------- start,end points are captured ------------------"
		
				set all_points_per_path [get_attribute $path points]
				echo "-------------- all points per path are captured ------------------"
				set all_objs_per_path [get_attribute $all_points_per_path object]
				echo "-------------- all objects per path are captured ------------------"
				#set all_op_objs_per_path [-filter_collection $all_objs_per_path "direction==out"]
				echo "-------------- all output objects per path are captured ------------------"
				set all_cells_per_path [get_cell -of_obj $all_objs_per_path]
				echo "-------------- all cells per path are captured ------------------"
				
				echo "----------------------- INITIAL REF_NAMES -----------------"
				set init_ref_names [get_attribute $all_cells_per_path ref_name]
				echo $init_ref_names
				echo "-------------- all intital ref names per path are captured ------------------"
				set filtered_coll_of_cells [get_cell -of_obj $all_objs_per_path -filter "ref_name!~*INV* && ref_name!~*BUF* && ref_name!~*SDFF*"]
				
				echo "----------------------- FINAL REF_NAMES -----------------"
				set final_ref_names [get_attribute $filtered_coll_of_cells ref_name]
				echo $final_ref_names
				
				set cell_count_per_path($i) [llength $final_ref_names]

				echo [format "number of non inv / buf cells in path : " ]
				#continue [lindex $path]
				echo [format "is : %d" $cell_count_per_path($i) ]
			}
				
			set len_of_arr [array size cell_count_per_path]
				
			for {set i 0} {$i < $len_of_arr} {incr i} {
				
				if {$cell_count_per_path($i) > $curr_count(0) } { 
				set req_index $i
				set curr_count(0) $cell_count_per_path($i)
				}
				
			}

		#set final_path [index_collection [get_timing_paths -max_paths $N -slack_lesser_than $SLT] $req_index]
		echo "============================================================================================="
		echo "============================================================================================="
		echo "=======================================TASK 1 OP is=========================================="
		echo "============================================================================================="
		echo "============================================================================================="
		echo "============================================================================================="
		echo "Path :\t"		
		return lindex $path $req_index

		} elseif {[string match -N* $option_N] && [string match -SLT* $option_SLT] && [string match -TRSH* $option_TRSH]} {
			# If Threshold is mentioned [my_proc -N 10000 -SLT 0 -TRSH 100]
	        echo "Threshold mentioned - inside 2nd elseif block"
			set N $value_N 
			set SLT $value_SLT
			set TRSH $value_TRSH
  
			echo "********************************************************************"
			echo " "
			echo " "
			echo [format " Given N    : %10s " $N]
			echo [format " Given SLT  : %10s " $SLT]
			echo [format " Given TRSH : %10s " $TRSH]
			echo " "
			echo " "
			echo "********************************************************************"
			echo " "
			echo " "
			echo " "
			echo " "
			echo " "
			echo "************************** REPORTING TIMING**************************"
			report_timing 
			echo "***************************REPORT_TIMING COMPLETE*********************************"
			echo " "
			echo " "
			echo " "
			echo " "
			echo " "
			#--------------------------------INTERNAL COUNTER VARIABLES AND ARRAYS-------------------------------------
			set cells 0
			set cellFound 0
			#array set count_cell {}
			array set cell_count_per_path {}
			set curr_count 0
			set req_index 0
			#----------------------------------------------------------------------------------------------------------
			
			echo [format "---------------------COMMAND : set all_paths [get_timing_paths -max_paths %10s -slack_lesser_than %10s -----------------" $N $SLT]]
			
			set all_paths [get_timing_paths -max_paths $N -slack_lesser_than $SLT]
			echo " "
			echo " "
			echo " "
			echo " "
			echo " "
			echo "-------------- all paths are captured ------------------"
			#echo $all_paths

			# To find the Total Number of cells in the each Timing Path

			foreach_in_collection path $all_paths {

				#set  start_points [get_attribute $path startpoint]
				#set  end_points [get_attribute $path endpoint]
				#echo "-------------- start,end points are captured ------------------"
		
				set all_points_per_path [get_attribute $path points]
				set all_objs_per_path [get_attribute $all_points_per_path object]
				set all_op_objs_per_path [filter_collection $all_objs_per_path "direction==out"]
				set all_cells_per_path [get_cell -of_obj $all_op_objs_per_path]
				
				#echo "----------------------- INITIAL REF_NAMES -----------------"
				#get_attribute $all_cells_per_path ref_name
				
				set filtered_coll_of_cells [get_cell -of_obj $all_op_objs_per_path -filter "ref_name!~*INV* && ref_name!~*BUF*"]
				
				echo "----------------------- FINAL REF_NAMES -----------------"
				get_attribute $filtered_coll_of_cells ref_name
				
				set cell_count_per_path(path) [array size filtered_coll_of_cells]
				echo [format "number of non inv / buf cells in path %10s is %10s" $path $cell_count_per_path(path)]
			}
				
			#set len_of_arr [array size cell_count_per_path]
				
			for {set i 0} {$i < TRSH} {incr i} {
				
				if {cell_count_per_path(i) > curr_count } { set req_index $i}
				
			}
		}
	
	
	}
