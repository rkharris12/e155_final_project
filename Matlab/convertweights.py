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
    
# #######
# #######
# #######

import csv

inputLayer = []
hiddenWeights = []
outputWeights = []
newrow = []

#with open('inputlayer.csv', newline='') as inputLayerFile:
#    inputLayerRead = csv.reader(inputLayerFile, delimiter=' ', quotechar='|')
#    for row in inputLayerRead:
#        if ('\ufeff' in row[0]):
#            row = row[0].split('\ufeff')[1].split(',')
#        else:
#            row = row[0].split(',')
#        for e in row:
#            newrow += [hex(int(e))[2::]]
#        inputLayer += [newrow]
#        newrow = []

with open('xtrain.csv', newline='') as inputLayerFile:
    inputLayerRead = csv.reader(inputLayerFile, delimiter=' ', quotechar='|')
    for row in inputLayerRead:
        row = row[0].split(',')
        for e in row:
            newrow += [e[2::]]
        inputLayer += newrow
        newrow = []

#with open('xtrain.csv', newline='') as inputLayerFile:
#    inputLayerRead = csv.reader(inputLayerFile, delimiter=' ', quotechar='|')
#    for row in inputLayerRead:
#        row = row[0].split(',')
#        for e in row:
#            newrow += [hex2(int(e))[2::]]
#        inputLayer += newrow
#        newrow = []

#with open('Whnew.csv', newline='') as hiddenWeightsFile:
#   hiddenWeightsRead = csv.reader(hiddenWeightsFile, delimiter=' ', quotechar='|')
#   for row in hiddenWeightsRead:
#       row = row[0].split(',')
#       for e in row:
#           newrow += [frac2bin(float(e))]
#       hiddenWeights += [newrow]
#       newrow = []
        
#with open('Wonew.csv', newline='') as outputWeightsFile:
#   outputWeightsRead = csv.reader(outputWeightsFile, delimiter=' ', quotechar='|')
#   for row in outputWeightsRead:
#       row =  row[0].split(',')
#       for e in row:
#           newrow += [frac2bin(float(e))]
#       outputWeights += [newrow]
#       newrow = []

#f = open("inputlayer.dat","w+")
#f.write('0x' + out.join(inputLayer) + "\r\n");  
#f.close()
        
f = open("inputlayer.dat","w+")

out = ''
for r in range(0, len(inputLayer)):
    f.write(out.join(inputLayer[r]) + "\r\n");
    out = ''
    
f.close()        
        
f = open("hiddenweights.dat","w+")

out = ''
for r in range(0, len(hiddenWeights)):
    f.write(out.join(hiddenWeights[r]) + "\r\n");
    out = ''
    
f.close()

f = open("outputweights.dat","w+")

out = ''
for r in range(0, len(outputWeights)):
    f.write(out.join(outputWeights[r]) + "\r\n");
    out = ''
    
f.close()

 
        