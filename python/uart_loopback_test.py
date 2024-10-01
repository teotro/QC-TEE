#!/usr/bin/python3.6

from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from bitstring import BitArray

import time
import serial
import argparse
import pdb

# Get command line arguments
parser = argparse.ArgumentParser(description='Serial port loopback design tester script.')
parser.add_argument('-b', '--baud', default=None, type=str, required=True, help='Baud rate of the serial port.')
parser.add_argument('-p', '--port', default=None, type=str, required=True, help='Serial port device name.')
args = parser.parse_args()

baud = args.baud
port = args.port

# Configure the serial connections (the parameters differs on the device you are connecting to)
ser = serial.Serial(
    port=port,
    baudrate=baud,
    parity=serial.PARITY_ODD,
    stopbits=serial.STOPBITS_TWO,
    bytesize=serial.EIGHTBITS
)

# Allow time for serial to initialize
time.sleep(0.2)
sub_key = []

value = get_random_bytes(16)

myfile = open("../tb/DUMMY_ENCRYPTED_DATA.mem")

bitmap = []

for line in myfile:
    x = line
    line = x.replace("\n","")
    val = int(line, base=2)
    val2= val.to_bytes(16, 'big')
    bitmap.append(val2)

block_size = int.to_bytes(len(bitmap), 1, 'big')
print("Block Size is: ")
print(block_size)
ser.write(block_size)

# ser.reset_input_buffer()
print("Block Size we got is: ")
c = ser.read()
print(c)

# Generate and send a random 128-bits AES key
# key = get_random_bytes(16)
key = bytes.fromhex('00000000000000000000000000000000')
print("Key sent is: ")
print(key)
ser.write(key)


ser.reset_input_buffer()

for i in range(0,16):
    print("Subkey " + str(i) + " we got: ")
    c = ser.read()
    print(c)


# myfile = open("../tb/DUMMY_ENCRYPTED_DATA.mem")

# bitmap = []

# for line in myfile:
#     x = line
#     line = x.replace("\n","")
#     val = int(line, base=2)
#     val2= val.to_bytes(16, 'big')
#     bitmap.append(val2)

# Encrypt and send the Bitmap
ciphertext = []
# tag = []
# nonce = []

for i in range (0, len(bitmap)):
    cipher = AES.new(key, AES.MODE_ECB) # ECB (Electronic Code Book) mode
    cipher_text = cipher.encrypt(bitmap[i])
    ciphertext.append(cipher_text)
    # tag.append(cipher_encryption_and_digestion[1])
    # nonce.append(cipher.nonce)

    # Need to check this: Send 128-bits ciphertext(=encr_data) only(?) Is it enough?
    print("Ciphertext sent for bitmap " + str(i) + " is: ")
    
    # print(ciphertext[i].hex())
    print(ciphertext[i])
    # print(value)
    ser.write(ciphertext[i])
    # ser.write(bitmap[i])
    # ser.write(value)

    print("=================================================================") 
    for i in range(0, 16):
        c = ser.read()
        print("Ciphertext " + str(i) + " received: ")
        print(c)

# time.sleep(20)
for j in range (0, len(bitmap)):
    print("=================================================================")
    print(" number of bytes in the input buffer", ser.in_waiting, '\n')
    for i in range(0, 16):
        c = ser.read()
        print("Decrypted bitmap vector " + str(j) + " piece " + str(i) + " received: ")
        print(c.hex())

print(" number of bytes in the input buffer", ser.in_waiting, '\n')
for i in range (0, 16):
    c = ser.read()
    print("Encrypted SHAKE output " + str(i) + " received:")
    print(c.hex())

# Send back to UART chunks of 7 from FIFO for debugging
for i in range(0, 112):
    c = ser.read()
    print("FIFO chunk output number " + str(i) + " received:")
    print(c.hex())