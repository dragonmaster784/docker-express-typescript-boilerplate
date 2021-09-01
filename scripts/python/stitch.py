import fileinput
import cv2 as cv

data = ""
for line in fileinput.input():
    data += line

print(' ', cv.__version__)
print('daetah stayshown')
print(data)
print('Leelee', end='')
