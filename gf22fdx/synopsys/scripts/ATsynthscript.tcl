################################################################################
################################################################################
##
##     gcmAes128Single-synth_eval.tcl
##
## Author:       Michael Muehlberghuber
## Filename:     gcmAes128Single-synth_eval.tcl
## Created:      Tue Jun  2 15:24:10 2015 (+0200)
## Last-Updated: Tue Jun  2 15:24:10 2015 (+0200)
##
## Description:  Synthesis script for evaluating the size of the GCM-AES-128
##               architecture based on a single stage.
##
################################################################################
################################################################################


################################################################################
#####                                                                          #
#####     Settings                                                             #
#####                                                                          #
################################################################################

## Name of the SystemVerilog module to be evaluated.
set module riscv_nn_core

## Name of the library to be used.
set lib WORK

## Maximum frequencies respectively maximum I/O delays in picoseconds, for which
## the design should be synthesized.
set periods {
2000
1333
1000
800
667
580
500
}

## We want to run synthesis for all the clock frequencies above once without and
## once with the TNN extensions
set tnn_ext_parameters {
0
1
}


## Directory to be used as root for all the runs.
set runDir "./AToutputs"

## Number of cores to be used for the synthesis runs.
set cpuCores 6
################################################################################


################################################################################
#####                                                                          #
#####     Start of Actual Script                                               #
#####                                                                          #
################################################################################

## Get global (comprising all synthesis runs) start time.
set globalStartTime "[clock seconds]"

## Create the (roo-)directory for the current runs.
file mkdir $runDir

## Log file to which all the (terminal) outputs should be written. Setting this
## file is done via the 'sh_output_log_file' variable provided by the Design
## Compiler. This is equal to providing the log file during the startup of the
## Design Compiler using the '-output_log_file' parameter. Since by default the
## outputs get appended to the file, we remove it first.
file mkdir logs
set synthOutputs "logs/AT_riscv_nn_core_synthesis_outputs.log"
set sh_output_log_file $synthOutputs

## File providing some information about the synthesis runs going on.
set runLog [open "logs/AT_riscv_nn_core_synthesis_status.log" w]

## Set the format of a date time
set dateTimeFormat "%Y_%m_%d-%H_%M_%S"

## Counter for counting the number of runs (depending on the number of
## periods/max delays and the architectures/confirgures defined).
set run 0

## Set the number of CPU cores to be used for synthesis
set_host_options -max_cores $cpuCores

## Provide some information about the synthesis runs to be started into the run
## log file.
set pers [llength $periods]
set runs $pers
puts $runLog "##"
puts $runLog "## RUNNING SYNTHESIS INFORMATION"
puts $runLog "##"
puts $runLog "## Synthesized Entity:           $module"
puts $runLog "## Number of Timing Constraints: $pers"
puts $runLog "## Overall Synthesis Runs:       $runs"
puts $runLog "## Number of CPU Cores Used:     $cpuCores"
puts $runLog "## Start of Synthesis Runs:      [clock format ${globalStartTime}]"
puts $runLog "##"
flush $runLog

## Perform synthesis runs for all defined architectures/configurations and
## periods/max delays.
foreach tnn_ext $tnn_ext_parameters {
	foreach period $periods {

		## Provide some information about the current run.
		incr run
		puts -nonewline $runLog "## Starting synthesis run number $run of $runs ($module-${period}ps) ... "
		flush $runLog

		## Subdirectory for current run with a certain period.
		if {$tnn_ext == 0} {
			set currRunDir "$runDir/no_tnn/${module}_${period}ps"
		} else {
			set currRunDir "$runDir/tnn/${module}_${period}ps"
		}

		## Start time of the compilation run.
		set startTime "[clock seconds]"

		## For the reports directory, use a period-specific suffix.
		set reportsDir "${currRunDir}/reports"

		## For the DDC directory, use a period-specific suffix.
		set ddcDir "${currRunDir}/ddc"

		## Create the required directories.
		file mkdir $currRunDir
		file mkdir $reportsDir
		file mkdir $ddcDir

		## Start from a fresh design.
		remove_design -design
		sh rm -rf $lib/*

		## Analyze the source files.
		source scripts/analyze.tcl

		## Elaborate the current configuration.
		elaborate $module -library WORK -parameters "TNN_EXTENSION=>${tnn_ext}"


		##### Set the constraints.

		## Set the clock period constraint.
		create_clock clk_i -period $period

		## Exceptions
		source -echo -verbose ./scripts/constraints/exceptions.sdc

		## Input output delays
		source -echo -verbose ./scripts/constraints/input_output_delay.sdc

		# Insert clock gate
		source -echo -verbose ./scripts/insert_clock_gating.tcl

		## Start compilation.
		compile_ultra

		## Save compiled design.
		write -f ddc -h -o $ddcDir/${module}_compiled.ddc

		## Create some reports.
		check_design                                                                              > $reportsDir/check_design-compiled.rpt
		report_area -hierarchy -nosplit                                                           > $reportsDir/area.rpt
		report_cell -nosplit [all_registers]                                                      > $reportsDir/registers.rpt
		report_reference -nosplit                                                                 > $reportsDir/references.rpt
		report_constraint -nosplit                                                                > $reportsDir/constraints.rpt
		report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins]            > $reportsDir/timing_ss.rpt
		report_timing -from [all_inputs] -to [all_registers -data_pins] -max_paths 10 -path end   > $reportsDir/timing_is.rpt
		report_timing -from [all_registers -clock_pins] -to [all_outputs] -max_paths 10 -path end > $reportsDir/timing_so.rpt
		report_timing -from [all_inputs] -to [all_outputs]                                        > $reportsDir/timing_io.rpt

		## Calculation the duration of the compilation run.
		set endTime "[clock seconds]"
		set duration [expr {$endTime - $startTime}]

		set vars    {seconds minutes hours days}
		set factors {60      60      24    7}
		foreach v $vars f $factors {
				set $v [expr {$duration % $f}]
				set duration [expr {($duration-[set $v]) / $f}]
		}
		set weeks $duration

		puts $runLog "done (Duration: $hours:$minutes:$seconds)"
		flush $runLog

		## Create a short summary.
		set sum "./$currRunDir/synthesis_summary.txt"

		echo "***** SYNTHESIS SUMMARY" > $sum
		echo "" >> $sum
		echo "Entity:            $module"     >> $sum
		echo "Clock Constraint:  ${period}ns" >> $sum
		echo "" >> $sum
		echo "Starttime:         [clock format ${startTime}]" >> $sum
		echo "Endtime:           [clock format ${endTime}]" >> $sum
		echo "Duration:          $hours hours, $minutes minutes, $seconds seconds" >> $sum
		echo "" >> $sum;
	}
}

## Calculate the global duration of all synthesis runs.
set globalEndTime "[clock seconds]"
set duration [expr {$globalEndTime - $globalStartTime}]
set vars    {seconds minutes hours days}
set factors {60      60      24    7}
foreach v $vars f $factors {
		set $v [expr {$duration % $f}]
		set duration [expr {($duration-[set $v]) / $f}]
}
set weeks $duration

## Print some information about the required time for all the synthesis runs.
puts $runLog "##"
puts $runLog "## End of Synthesis Runs:        [clock format ${globalEndTime}]"
puts $runLog "## Duration:                     $hours:$minutes:$seconds"
puts $runLog "##"
puts $runLog "## SYNTHESIS RUNS DONE"
puts $runLog "##"
close $runLog
exit
