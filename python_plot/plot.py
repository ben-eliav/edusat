import os
import sys
import glob
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
import re

def parse(f):
    data = open(f).read()
    if 'TIMEOUT' in data or '###' not in data:
        return None
    parsed = list(map(float, re.findall(r'### .*?:\s*(\d+\.?\d*)', data)))
    # Restarts, Learned-clauses, Decisions, Implications, Time
    # if len(parsed) != 5:
    #     return None
    return parsed

def plot(label, data):
    # x = problems solved
    # y = cpu time (seconds)
    x = np.arange(len(data) + 1)
    y = np.array([0] + sorted(data))
    plt.plot(x, y, label=label, marker='.')

def plotall(titles, data):
    for title, lines in zip(titles, data):
        plt.figure()
        plt.title(title.capitalize())
        plt.xlabel('Problems')
        plt.ylabel(title.capitalize())
        for label, line in lines:
            plot(label, line)
        plt.legend()
    #plt.xscale('log')
        plt.savefig(f'{title}_hard.png')
    plt.show()
    

def main():
    titles = 'Restarts,Learned-clauses,Decisions,Implications,Time (seconds)'.split(',')
    data = [[] for i in titles]
    path = r"C:\Users\shirel\CLionProjects\edusat\shirel_tests"
    for folder in os.listdir(path):
        if 'hard' not in folder:
            continue
        files = glob.glob(os.path.join(path, folder, '*'))
        parsed = list(filter(None, map(parse, files)))
        print(f'{folder}\tfiles: {len(files)}\tparsed:{len(parsed)}')
        for index, line in enumerate(zip(*parsed)):
            data[index].append((folder, line))
    plotall(titles, data)
    
if __name__ == '__main__':
    main()

