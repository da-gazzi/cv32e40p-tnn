from matplotlib import pyplot as plt
import pandas as pd
import subprocess

if __name__=='__main__':
    # run bash script to grep the period, slack and area values from various synopsys reports
    try:
        subprocess.run(['./getATValues.sh', 'riscv_nn_core'])
    except PermissionError:
        print('getATValues.sh does not have execution permission - will be changed using chmod')
        subprocess.run(['chmod', '+x', 'getATValues.sh'])
        subprocess.run(['./getATValues.sh', 'riscv_nn_core'])

    df_tnn = pd.read_csv('at_data/riscv_nn_core_at_values_tnn.dat', sep="\t", header=None).sort_values(by=[0])
    df_notnn = pd.read_csv('at_data/riscv_nn_core_at_values_notnn.dat', sep="\t", header=None).sort_values(by=[0])

    periods_tnn = df_tnn[0].values
    slacks_tnn = df_tnn[1].values
    areas_tnn = df_tnn[2].values

    periods_notnn = df_notnn[0].values
    slacks_notnn = df_notnn[1].values
    areas_notnn = df_notnn[2].values

    assert (periods_tnn==periods_notnn).all(), 'Periods mismatching'

    plt.style.use('fivethirtyeight')

    periods = periods_notnn / 1000
    plt.plot(periods, areas_notnn, marker='o', label='No TNN extensions')
    plt.plot(periods, areas_tnn, marker='o', label='TNN extensions')

    plt.xlabel('Periods (ns)')
    plt.ylabel('Area um^2')
    plt.title('AT plot for RI5CY without and with TNN extensions')

    plt.legend()
    plt.savefig('plot.png')

    plt.show()