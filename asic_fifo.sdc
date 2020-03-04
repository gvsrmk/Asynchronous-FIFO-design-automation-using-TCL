# clock creation
set WCLK_PERIOD 1.2
set WCLK2X_PERIOD [expr $WCLK_PERIOD/2.0]
create_clock -name "wclk" -period $WCLK_PERIOD -waveform {0.0 0.6} wclk
create_clock -name "wclk2x" -period [expr $WCLK2X_PERIOD] -waveform {0.0 0.3} wclk2x
create_clock -name "rclk" -period 1.2 -waveform {0.0 0.6} rclk



# Network latency of 0.3ns
set_clock_latency 0.1 [get_clocks wclk]
set_clock_latency 0.1 [get_clocks wclk2x]
set_clock_latency 0.1 [get_clocks rclk]


# Clock uncertainty(Setup & hold)
set_clock_uncertainty 0.1 [get_clocks wclk]
set_clock_uncertainty 0.1 [get_clocks wclk2x]
set_clock_uncertainty 0.1 [get_clocks rclk]


# clock transition time(rise & fall)
set_clock_transition 0.1 [get_clocks wclk]
set_clock_transition 0.1 [get_clocks wclk2x]
set_clock_transition 0.1 [get_clocks rclk]


# false path
set_false_path -from [get_clocks wclk] -to [get_clocks rclk]
set_false_path -from [get_clocks rclk] -to [get_clocks wclk]


#Input delay
set_input_delay 0.2 -clock wclk {wdata_in winc}
set_input_delay 0.1 -clock wclk2x {wdata_in}
set_input_delay 0.1 -clock rclk {rinc}


#output delay
set_output_delay 0.01 -clock rclk {rdata rempty}
set_output_delay 0.1 -clock wclk {wfull}


# setting output load
set_load 0.1 rdata

#setting drive
set_drive 0.001 wdata_in


#group_path -name INTERNAL -from [all_clocks] -to [all_clocks ]
group_path -name INPUTS -from [ get_ports -filter "direction==in&&full_name!~*clk*" ]
group_path -name OUTPUTS -to [ get_ports -filter "direction==out" ]

