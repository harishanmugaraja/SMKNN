# Tony Liang and hari Shanmugaraja
# Feb 9 2020
# read in text file for lidar and text file for car motor and steering and match them up
# sample line
# 1581083570.228828 b'8597 1407\r\n'
#
#
# Ultra simple LIDAR data grabber for RPLIDAR.
# Version: 1.10.0
# 1582122195.06
# RPLIDAR S/N: BE9B9AF2C1EA98D4BEEB9CF031483517
# Firmware Ver: 1.25
# Hardware Rev: 5
# RPLidar health status : 0
#    theta: 0.30 Dist: 00781.00 Q: 47
#    theta: 1.05 Dist: 00780.00 Q: 47
#    theta: 1.55 Dist: 00789.00 Q: 47
#    theta: 2.17 Dist: 00782.00 Q: 47
#    theta: 3.09 Dist: 00000.00 Q: 0
#    theta: 3.55 Dist: 01044.00 Q: 47


#output: big list: inside list: 360 (theta, dist) tuples followed by motor, steering
import sys
import random
import subprocess
#import serial
import time
import os
import signal

filename = "steeringdata.txt"
print("cardatafile lidardatafile offset -copy and paste: steeringdatacar.txt steeringdatalidar.txt 1.5")
threeinputs = input()
splitupinputs = threeinputs.split(" ")
lidarFile = splitupinputs[1]
carFile = splitupinputs[0]#"steeringdatacarsample.txt"
arduinoTimeToLidarTime = dict()#maps arduino time to closest lidar time
lidarTimeToArduinoTime = dict()

offset = float(splitupinputs[2])  # offset accounts for time difference between pi and tony's computer - this is
#tony's computer - pi computer. Positive if tonys computer is ahead
timeToValues = dict()#arduino time to steering data
timeList = list()#list of times from arduino

timeListLidar = list()#list of times from pi
timeToLidarPoints = dict()#list of times from pi  + offset to lidar points
finalList = list()

def findClosestTime(time, options):
    absolute_difference_function = lambda list_value: abs(list_value - time)

    closest_value = min(options, key=absolute_difference_function)

    return closest_value

def main():
    global timeList, timeToValues
    with open(carFile) as f:
        for line in f.readlines():
            splitupline = line.split(" ")
            if len(splitupline) == 3:
                time = float(splitupline[0])
                motor = int(splitupline[1].lstrip("b'"))
                steering = int(splitupline[2][0:4])
                timeList.append(time)
                valueList = [motor, steering]
                #valueTuple = tuple(valueList)
                timeToValues[time] = valueList
        f.close()
        timeList = tuple(timeList)
    #print(timeList)
    #print(timeToValues)

    with open(lidarFile) as fl:
        lineNumber = 0
        currentPoints = list()
        currentTime = None
        for line in fl.readlines():
            lineNumber = lineNumber + 1
            strippedLine = line.strip(" ")
            splitWords = strippedLine.split(" ")
            if "theta" in line and "S" not in line :
                #print(splitWords)#debug
                theta = float(splitWords[1])
                dist = float(splitWords[3])
                pointList = [theta, dist]
                pointTuple = tuple(pointList)
                currentPoints.append(pointTuple)

            elif len(line.split(" ")) == 1 and len(currentPoints) > 10: #this is the line where only time is printed, reset currentpoints and currenttime
                #print(currentPoints)
                print(len(currentPoints))
                print(lineNumber)
                while len(currentPoints) > 361: #cut currentPoints to exactly 360 or add if youre short
                    random_item = random.choice(currentPoints)#361 bc we dump the first data point
                    currentPoints.remove(random_item)
                while len(currentPoints) < 361:#rare occasion that points is below 360
                    random_item = random.choice(currentPoints)#duplicate some
                    currentPoints.append(random_item)
                currentTime = float(line.strip("\n"))
                timeListLidar.append(currentTime + offset)
                timeToLidarPoints[currentTime + offset] = currentPoints[1:]
                currentPoints = list()
                currentTime = None
#print(" ")
    #for t in timeToLidarPoints:
    #    print(t, timeToLidarPoints[t])
    #print(timeListLidar)
    #print(timeList)
    #print(timeToLidarPoints.keys())
    for t in timeList:#Do not comment out
        closestLidarTime = findClosestTime(t, timeListLidar)
        arduinoTimeToLidarTime[t] = closestLidarTime
        #lidarTimeToArduinoTime[closestLidarTime] = t
    print(" ")
    #print(arduinoTimeToLidarTime)#continue working here
    #for t in timeToLidarPoints:
    #    print (len(timeToLidarPoints[t]))
    for t in timeList:#DO not comment out
        #print(timeToValues[t])
        #print(timeToLidarPoints[arduinoTimeToLidarTime[t]])
        #print(timeToValues[t])

        toAppend = timeToLidarPoints[arduinoTimeToLidarTime[t]] + timeToValues[t]
        #print(toAppend)
        finalList.append(toAppend)


    for finalForm in finalList:
        print(finalForm)







if __name__ == "__main__":
    main()
