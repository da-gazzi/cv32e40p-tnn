%%%% 
%%%% Script for extracting all AT data and plot them
%%%%

%% Set used clock constraints
% make sure this corresponds with the timing constraints 
% in the compile script
time=[2.00 3.00 4.00 5.00 6.00 7.00 8.00 9.00];


%% call bash script to grep out the data from the reports
!./getATValues.sh p_fma_top

%% read these collected data
file=fopen('at_data/p_fma_top_at_values.dat');
AT=fscanf(file,'%e',length(time)*3);
fclose(file);

%% Plot the AT data
% odd values are slack values, even values are area values
slacks = AT(2:3:length(AT));
periods = -slacks + time';

area_kGE = AT(3:3:length(AT))./1.44/1000;

%plot(-AT(2:3:length(AT))+time',AT(3:3:length(AT))./1.44/1000,'linestyle',':', 'marker','x','linewidth',2,'markeredgecolor','k');
plot(periods,area_kGE,'linestyle',':', 'marker','x','linewidth',2,'markeredgecolor','k');

grid on;
box on;
xlabel('T [ns]');
ylabel('A [kGE]');
title('AT plot for Posit FMA');
