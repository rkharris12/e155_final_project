# Veronica Cortes
# vcortes@g.hmc.edu
# 16 November 2019

# ----------------
# Binary Math
# ----------------

import math

def num2bin(num, str):
    if (int(num) == 0):
        while(len(str) < 8):
            str = "0" + str    
        return str
    elif (int(num) == 1):
        str = "1" + str
    elif (int(num) % 2 == 1):
        str = "1" + str
    else:
        str = "0" + str
    return num2bin(int(num)/2, str)
    
def bin2hex(numStr):
    hx = ''
    
    conv = {
        '0000': '0',
        '0001': '1',
        '0010': '2',
        '0011': '3',
        '0100': '4',
        '0101': '5',
        '0110': '6',
        '0111': '7',
        '1000': '8',
        '1001': '9',
        '1010': 'A',
        '1011': 'B',
        '1100': 'C',
        '1101': 'D',
        '1110': 'E',
        '1111': 'F'
    }
    
    parts = [numStr[i:i+4] for i in range(0,len(numStr),4)]
    for e in parts:
        hx += conv[e]
    return hx
    
def xorStr(strA, strB):
    newStr = ''
    tt = {
        '00': '0',
        '01': '1',
        '10': '1',
        '11': '0',
    }
    AB = ''
    for i in range(0,len(strA)):
        AB = strA[i] + strB[i]
        newStr += tt[AB]
    return newStr
    
def addBinOne(binStr):
    revBinStr = binStr[::-1]
    c = 0
    newStr = ''
    if (revBinStr[0] == '1'):
        newStr = '0' + newStr
        c = 1
    elif (revBinStr[0] == '0'):
        newStr = '1' + newStr
    for i in range(1,len(revBinStr)):
        if (revBinStr[i] == '1' and c == 1):
            newStr = '0' + newStr
        elif (revBinStr[i] == '0' and c == 1):
            newStr = '1' + newStr
            c = 0
        elif (revBinStr[i] == '1' and c == 0):
            newStr = '1' + newStr
        else:
            newStr = '0' + newStr
    return newStr
 
def twosComp(binStr):
    #return (num^-1)+1; 
    return addBinOne(xorStr(binStr,'1111111111111111'))
    
def hex2(num):
    if (num < 16):
        return '0x0' + hex(num)[2::]
    else:
        return hex(num)

def bin2frac(binStr):
    str = binStr
    exp = -1
    sum = 0
    if (binStr[0] == '1'):
        str = twosComp(str)
        sum += -1
    for e in binStr[1::]:
        sum += float(e)*pow(2, exp)
        exp -= 1
    return sum
        
def frac2bin(num):
    str = ''
    mag = abs(num)
    exp = -1
    count = 0
    while (mag > 0 and count < 7):
        if mag >= pow(2,exp):
            str += '1'
            mag -= pow(2,exp)
        else:
            str += '0'
        #print(mag)
        exp -= 1
        count += 1
    str = '0' + str
    if (num < 0):
        str = twosComp(str)
    while (len(str) < 8):
        str += '0'
    #print(str)
    return str
    
# ----------------
# Load in CSVs
# ----------------

import csv

inputLayer = []
hiddenWeights1 = []
hiddenWeights2 = []
hiddenWeights3 = []
outputWeights = []
newrow = []

with open('xtrain_q15.csv', newline='') as inputLayerFile:
    inputLayerRead = csv.reader(inputLayerFile, delimiter=' ', quotechar='|')
    for row in inputLayerRead:
        row = row[0].split(',')
        for e in row:
            newrow += [e]
        inputLayer += [newrow]
        newrow = []

with open('wh1_q15.csv', newline='') as hiddenWeights1File:
    hiddenWeights1Read = csv.reader(hiddenWeights1File, delimiter=' ', quotechar='|')
    for row in hiddenWeights1Read:
        row = row[0].split(',')
        for e in row:
            newrow += [e]
        hiddenWeights1 += [newrow]
        newrow = []

with open('wh2_q15.csv', newline='') as hiddenWeights2File:
    hiddenWeights2Read = csv.reader(hiddenWeights2File, delimiter=' ', quotechar='|')
    for row in hiddenWeights2Read:
        row = row[0].split(',')
        for e in row:
            newrow += [e]
        hiddenWeights2 += [newrow]
        newrow = []        
        
with open('wh3_q15.csv', newline='') as hiddenWeights3File:
    hiddenWeights3Read = csv.reader(hiddenWeights3File, delimiter=' ', quotechar='|')
    for row in hiddenWeights3Read:
        row = row[0].split(',')
        for e in row:
            newrow += [e]
        hiddenWeights3 += [newrow]
        newrow = []           
        
with open('wo_q15.csv', newline='') as outputWeightsFile:
    outputWeightsRead = csv.reader(outputWeightsFile, delimiter=' ', quotechar='|')
    for row in outputWeightsRead:
        row = row[0].split(',')
        for e in row:
            newrow += [e]
        outputWeights += [newrow]
        newrow = []        
        
# ----------------
# Write DATs
# ----------------
        
f = open("inputlayer.dat","w+")

out = ''
for r in range(0, len(inputLayer)):
    f.write(out.join(inputLayer[r]) + "\r\n");
    out = ''
    
f.close()        
        
f = open("hiddenweights1.dat","w+")

out = ''
for r in range(0, len(hiddenWeights1)):
    f.write(out.join(hiddenWeights1[r]) + "\r\n");
    out = ''
    
f.close()

f = open("hiddenweights2.dat","w+")

out = ''
for r in range(0, len(hiddenWeights2)):
    f.write(out.join(hiddenWeights2[r]) + "\r\n");
    out = ''
    
f.close()

f = open("hiddenweights3.dat","w+")

out = ''
for r in range(0, len(hiddenWeights3)):
    f.write(out.join(hiddenWeights3[r]) + "\r\n");
    out = ''
    
f.close()

f = open("outputweights.dat","w+")

out = ''
for r in range(0, len(outputWeights)):
    f.write(out.join(outputWeights[r]) + "\r\n");
    out = ''
    
f.close()
