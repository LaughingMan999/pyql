# plot fitted vs bid/ask vol at selected maturities

import pandas
import matplotlib.pyplot as plt
from pandas import DataFrame

def calibration_subplot(ax, group, i):
    group = group.sort_index(by='K')
    dtExpiry = group['dtExpiry'][0]
    K = group['K']
    VB = group['VB']
    VA = group['VA']
    VM = group['IVModel']

    ax.plot(K, VA, 'b.', K,VB,'b.', K,VM,'r-')
    if i==3:
        ax.set_xlabel('Strike')
    if i==0:
        ax.set_ylabel('Implied Vol')
    ax.set_title('Expiry: %s' % dtExpiry)
    
def calibration_plot(title, df_calibration):
    df_calibration = DataFrame.filter(df_calibration,
                    items=['dtExpiry', 
                           'K', 'VB', 'VA',
                           'T', 'IVModel'])

    # group by maturity
    grouped = df_calibration.groupby('dtExpiry')

    all_groups = [(dt, g) for dt, g in grouped]
    
    xy = [(0,0), (0,1), (1,0), (1,1)]

    for k in range(0, len(all_groups),4):
        if (k+4) >= len(all_groups):
            break
        plt.figure()
        fig, axs = plt.subplots(2, 2, sharex=True, sharey=True)

        for i in range(4):
            x,y = xy[i]
            calibration_subplot(axs[x,y], all_groups[i+k][1],i)
        fig.suptitle(title, fontsize=12, fontweight='bold')
        fig.show()


df_calibration = pandas.load('data/df_calibration_output_no_smoothing.pkl')

dtTrade = df_calibration['dtTrade'][0]
title = 'Heston Model (%s)' % dtTrade
calibration_plot(title, df_calibration)
