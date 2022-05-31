#!/bin/bash

#script extracts AT values from a bunch of synthesis reports with the same basename
#make sure that only one report_area and report_timing command was issued per file

cd "$(dirname "${BASH_SOURCE[0]}")"

RPRT_BASENAME=$1

OUTPUT_FILE="../results_analysis/at_data/"$RPRT_BASENAME"_at_values.dat"

rm -f $OUTPUT_FILE

touch $OUTPUT_FILE

for DIR in ../AToutputs/${RPRT_BASENAME}_*; do

	FILE=$DIR/reports/area.rpt
	AREA=`grep "Total cell area:" $FILE | sed -e "s/[^(0-9.)]//g"`

	FILE=$DIR/reports/timing_ss.rpt
	SLACK=`grep "slack (" $FILE | grep -Eo '\-?[0-9]+\.[0-9]+\s*$' | tail -n 1`
	CLK=`grep -E '^\s*clock.*?\(rise edge\)' $FILE | grep -Eo '[0-9]+\.[0-9]+\s*$' | tail -n 1`

	echo "$CLK $SLACK  $AREA" >> $OUTPUT_FILE

done
