#!/usr/bin/env python
# -*- coding: utf-8 -*-

import datetime
import time

import os

def parseBagFileNameForDateTime(file_name):

	# file_name: mapping_van_2019-10-18-20-39-30_12.bag
	date_time = file_name.split('_')[2]
	date_time = date_time.split('-')
	date_time = '-'.join(date_time[0:3]) + ' ' + ':'.join(date_time[3:6])

		# date_time: 2019-10-18 20:39:30
	return date_time

def parseBagFileNameForSplitFileIndex(file_name):

	# file_name: mapping_van_2019-10-18-20-39-30_12.bag
	split_file_index = file_name.split('_')[3]
	# print (split_file_index)
	split_file_index = split_file_index.split('.')[0]
	# print (split_file_index)
	return int(split_file_index)  # 12

def unixTimeToTimeStamp(unix_time):

	return datetime.datetime.fromtimestamp(int(unix_time)).strftime('%Y-%m-%d %H:%M:%S')

		# input 0, output 1970-01-01 00:00:00

	'''
		a.How to Print Without Newline? python2, print is a statment, pyhton3 print is a function
			1. for python3, use end= 
				print("Hello World!", end = '')
				print("My name is Karim")
				# output:
				# Hello World!My name is Karim
			2. for python2, use a comma at the end of your print statement
				print "Hello World!",
				print "My name is Karim"
				# output
				# Hello World! My name is Karim

		b.Print iterations progress
		# http://stackoverflow.com/questions/3173320/text-progress-bar-in-the-console/34325723#34325723
		# https://gist.github.com/aubricus/f91fb55dc6ba5557fbab06119420dd6a
	'''

def printProgress(iteration, total, prefix='', suffix='', decimals=1, length=100, fill='█'):
	"""
	Call in a loop to create terminal progress bar
	@params:
		iteration   - Required  : current iteration (Int)
		total       - Required  : total iterations (Int)
		prefix      - Optional  : prefix string (Str)
		suffix      - Optional  : suffix string (Str)
		decimals    - Optional  : positive number of decimals in percent complete (Int)
		length      - Optional  : character length of bar (Int)
		fill        - Optional  : bar fill character (Str)
	"""

	percent = ("{0:." + str(decimals) + "f}").format(100 *(iteration / float(total)))
	# filledLength = int(length * iteration // total)
	# bar = fill * filledLength + '-' * (length - filledLength)
	print('\r%s %s%% %s' % (prefix, percent, suffix), end='\r') # python 3
	# print('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix),) # python 2

	# Print New Line on Complete
	if iteration == total:
		print()

'''
Changes made:
	1. Added import time
	2. Added the 2 functions below
'''
def get_start_time():
	return time.time()

def display_runtime(start_time, time_type, is_subtopic = True):
	# Calculate the run time and print
	end_time = time.time()
	total_time = round((end_time - start_time), 4)
	print(f"\n{time_type} Runtime: {total_time} seconds")
	
	# Depending on whether it's a subtopic or not, change the dashlength
	dash_length = 125
	if (is_subtopic == True):
		print("-" * dash_length)
	else:
		print("─" * dash_length)
	
	return total_time


'''
Helper function that tries to make a new directory given a path and folder name.
'''
def make_folder(path, folder):
    # Make a new directory if it does not already exist
    try:
        os.makedirs(path)
        print(f"Folder '{folder}' created successfully.\n")

    except FileExistsError:
        print(f"Did not create new folder as {folder} already exists.\n")

def print_file_list(file_list):
	# Display information about the files that will be read
	print(f"Reading all {len(file_list)} file(s) in the current directory:")

	for f in file_list:
		print(f"\t{f}")
	
	print("─" * 125)

'''

'''

# Calculate data throughput
#   - Is it a network limit?
#   - Where does it make sense to do processing? on vehicle, on cloud, on edge computer?
#       - Moving data off vehicle takes a long time
#   - write to it both at start and at end (include intermediate steps?) 
#       - in case of crashing (corrupted file or power loss)
#   
def add_to_time_log_row(csv_row, key, val):
    if csv_row[key] is None:
        csv_row[key] = [val]
    else:
        csv_row[key].append(val)

    return csv_row