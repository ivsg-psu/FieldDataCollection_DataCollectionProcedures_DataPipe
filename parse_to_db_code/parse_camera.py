#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Revision history: 2022 02 16, fixed some comments.
'''
python 3.9

This script parse data in bagfile and then store them into PostgreSQL database.

Accepts a filename as an optional argument. Operates on all bagfiles in current directory if no argument provided

Written by Xinyu Cao at 2023 Nov. at IVSG

Supervised by Professor Sean Brennan
'''

import hashlib
import os
import numpy as np
import datetime
import cv2

import psycopg2
import rosbag
import pandas as pd
import polars as pl

import parse_utilities

class parseCamera:

	'''
		============================= Method md5Image() ====================================
		#	Method Purpose:
		#		produce the md5 hash code for string
		#	Input Variable:
		#		img:
		#
		#	Output/Return:
		#		None
		#
		#	Algorithm:
				# initializing string
		str = "GeeksforGeeks"

		# encoding GeeksforGeeks using encode()
		# then sending to md5()
		result = hashlib.md5(str.encode())

		# printing the equivalent hexadecimal value.
		print("The hexadecimal equivalent of hash is : ", end ="")
		print(result.hexdigest())
		#
		# 	Restrictions/Notes:
		# 		None
		#
		# 	The follow methods are called:

		# 	Author: Liming Gao
		# 	Date: 02/05/2020
		#
		================================================================================
	'''

	def __init__(self, pathForRootFolder, PathForCurrentBag, destinationPath, bag_file, hashName_Cameras, bag_file_db_id, to_db, db):
		self.pathForRootFolder = pathForRootFolder
		self.PathForCurrentBag = PathForCurrentBag
		self.destinationPath = destinationPath
		self.bag_file = bag_file
		self.hashName_Cameras = hashName_Cameras
		self.bag_file_db_id = bag_file_db_id
		self.to_db = to_db
		self.db = db

		# self.output_file_name = output_file_name

		'''
		============================= Method make_sure_path_exists() ====================================
		#	Method Purpose:
		#		check if the expected folder exists, if not create one
		#
		#	Input Variable:
		#		self, path
		#
		#	Output/Return:
		#		None
		#
		#	Algorithm:
				create a directory in path
		#
		# 	Restrictions/Notes:
		# 		None
		#
		# 	The follow methods are called:

		# 	Author: Liming Gao
		# 	Date: 02/05/2020
		#
		================================================================================

	'''

	def make_sure_path_exists(self, path):

		try:
			os.makedirs(path)
		except OSError as exception:
			pass
			# print('This folder already exists:', path)


	def md5Image(self, img):

		# img.tostring()
		md5Image = hashlib.md5(img.tostring()).hexdigest()

		return md5Image

	'''
		============================= Method saveMD5Image() ====================================
		Method Purpose:
			save img into the folder with hash value filename as .jpg format
		Input Variable:
			img:

		Output/Return:
			None

		Algorithm:
			cv2.imwrite(filename, img[, params])
			cv2.imwrite('img_CV2_90.jpg', a, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
		Restrictions/Notes:
			None

		The follow methods are called:

		Author: Liming Gao
		Date: 02/05/2020

		================================================================================
	'''

	def saveMD5Image(self, image_topic,img):

		md5_filename = self.md5Image(img)

		# create folder according to hash valus of img (delete later)
		camera_sub_folder =  image_topic.replace("image_rect_color/compressed","")

		# cameraHashBranch = self.destinationPath + '/' + self.hashName_Cameras + camera_sub_folder + md5_filename[0:2] + '/' + md5_filename[2:4]
		
		# No sub folder for each camera, save all images in the same hash table
		cameraHashBranch = self.destinationPath + '/' + self.hashName_Cameras + '/' + md5_filename[0:2] + '/' + md5_filename[2:4]
		self.make_sure_path_exists(cameraHashBranch)
		# create the file name using the hash value of img
		cameraHashLeaf = cameraHashBranch + '/' + md5_filename + '.jpg'
		

		# from 0 to 100 (the higher is the better). Default value is 95.
		cv2.imwrite(cameraHashLeaf, img, [int(cv2.IMWRITE_JPEG_QUALITY), 100])

		return md5_filename

	def rotateImage(self, img, angle):

		(h, w) = img.shape[:2]
		center = (w/2, h/2)

		M = cv2.retval = cv2.getRotationMatrix2D(center, angle, scale=1.0)
		# M = cv2.retval = cv2.getRotationMatrix2D((w/2, h/2), angle, scale=1.0)
		rotated = cv2.warpAffine(img, M, (w, h))

		return rotated

	def unixTimeToTimeStamp(self, unix_time):

		return datetime.datetime.fromtimestamp(int(unix_time)).strftime('%Y-%m-%d %H:%M:%S')
	
	'''
	===========================================================================================
	'''
	def createCameraDFRow(self, data, md5_filename, header_time_nanoseconds, bag_time_nanoseconds):
		# Finding infomration to store
		camera_hash = md5_filename
		root_folder_name = self.destinationPath

		file_size = os.path.getsize(self.PathForCurrentBag)

		# Calculate timing variables
		header_time_combined = header_time_nanoseconds
		ros_header_seconds = header_time_nanoseconds[:10]
		ros_header_nanoseconds = header_time_nanoseconds[10:]

		# Create a dictionary row with this inforrmation
		data.append({
			'bag_file_db_id' : self.bag_file_db_id,
			'camera_hash' : camera_hash,
			'camera_hash_root_folder_name' : root_folder_name,
			'camera_file_size' : file_size,
			'written_to_bag_time' : bag_time_nanoseconds,
			'ros_header_time' : header_time_combined,
			'ros_header_seconds' : ros_header_seconds,
			'ros_header_nanoseconds' : ros_header_nanoseconds
		})

		# Print information about the data frame
		# temp_df = pl.DataFrame(data)
		# print(temp_df)

		# print(f"'bag__db_id:' {self.bag_file_db_id}, 'cam_hash:' {camera_hash}, 'cam_hash_root_folder:' {root_folder_name}")
		
		return data
		
	def createCameraDF(self, topic, data):
		# Make sure there was no mistake with no data being found
		if (len(data) > 0):
			df = pl.DataFrame(data)   # Create a data frame out of this data

			table_name = "camera"
			db_col_lst = ["bag_file_db_id", "camera_hash", "camera_hash_root_folder_name",
							"camera_file_size", "written_to_bag_time",
							"ros_header_seconds", "ros_header_nanoseconds", "ros_header_time"]

			time_lst = ['written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time']

			# Update each time column to be of type Int64
			for t in time_lst:
				df = df.with_columns(pl.col(t).cast(pl.Int64))

			# Display the data frame
			# display_df = 0
			# if (display_df == 1):
			# 	print(f"\nTotal size of '{topic}' updated data frame: {df.shape}")
			# 	print(f"Displaying the first 3 rows of '{topic}' updated data frame: ")
			# 	print(df.head(3))

			# Write to the database if needed
			# if (self.to_db == 1):
			# 	if table_name != None:
			# 		# print("\nWriting to the database...")
			# 		self.db.df_to_db(table_name, df, db_col_lst)
			# 	else:
			# 		print("Table not in database.")
		
		# If an error occured while trying to make the data frame, print an error and set the df to be an empty Polars data frame
		else:
			print("Error creating dataframe.")
			df = pl.DataFrame()
		
		return df, table_name, db_col_lst
	
	'''
	===========================================================================================
	'''

	'''
		============================= Method parseCamera() ====================================
		#	Method Purpose:
		#		parse the Camera data into txt file and inser them into database 
		#
		#	Input Variable:
		#		sensor_id			3,4,5
		#		bag_file_id 		return when insert bag data
		#		bag_file           	bag = rosbag.Bag(bag_file_name)
		# 		camera_info_topic	camera_info_topic = '/front_center_camera/camera_info'
		# 		image_topic			image_topic = '/front_center_camera/image_rect_color/compressed'
		# 		output_file_name_images 	output_file_name_images = folder_name + '/images/' + bag_file_name.replace('.bag', '-front_center_camera-header.txt')
		# 		output_file_name_camera_info	output_file_name_camera_info = folder_name + '/images/' + bag_file_name.replace('.bag', '-front_center_camera-info.txt')
		#
		#
		#	Output/Return:
		#		None
		#
		#	Algorithm:
		#
		#
		# 	Restrictions/Notes:
		#
		#
		# 	The follow methods are called:
		#		parseUtilities.printProgress
		#
		# 	Author: Liming Gao
		# 	Date: 02/05/2020
		#
		================================================================================

	'''

	def parseCamera(self, image_topic, output_file_name_images,rotate=False, angle=0):
		# NOTE: The following comment-out lines are old script for a record, will be deleted later after review
		# file = open(output_file_name_camera_info, "w")

		# count = 0
		# for topic, msg, t in bag_file.read_messages(topics=[camera_info_topic]):

		# 	if count == 0:
		# 		file.write(str(msg.width))
		# 		file.write(',')
		# 		file.write(str(msg.height))
		# 		file.write(',')
		# 		file.write(', '.join(map(str, msg.K)))  # This removes the leading and lagging parentheses from this message
		# 		file.write(',')
		# 		file.write(', '.join(map(str, msg.D)))  # This removes the leading and lagging parentheses from this message
		# 		file.write('\n')

		# 		break

		# 		# K_left = np.array(msg.K).reshape((3, 3))
		# 		# D_left = np.array(msg.D)
		# 	count += 1

		# file.close()
		#values=[bag_file_id,sensor_id, msg.K[0], msg.K[4], msg.K[2], msg.K[5], msg.K[1], msg.width, msg.height, msg.D[0], msg.D[1], msg.D[2], msg.D[3], msg.D[4]]

		''' *** '''
		# Declare and initialize an empty data list. We will store rows of data here
		data = []
		''' *** '''
		
		file = open(output_file_name_images, "w")
		# Write header to the txt file
		Camera_info_header = "Camera Index, Local Time, ROS Time Second, ROS Time Nanosecond, ROS Time (nanosecond), Bag Time (nanosecond), Camera Hashtag"
		file.write(Camera_info_header + "\n")
		number_of_messages = self.bag_file.get_message_count(topic_filters=image_topic)

		count_of_camera_frame = 1
		for topic, msg, bag_timestamp in self.bag_file.read_messages(topics=[image_topic]):
			# This must be used for compressed images. CvBridge does not
			# support compressed images.
			# http://wiki.ros.org/rospy_tutorials/Tutorials/WritingImagePublisherSubscriber
			np_arr = np.fromstring(msg.data, np.uint8)
			img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

			if rotate is True:
				img = self.rotateImage(img, angle)

			# This can be used for raw images, but not for compressed. CvBridge
			# does not support compressed images.
			# https://gist.github.com/wngreene/835cda68ddd9c5416defce876a4d7dd9
			# try:
			# 	img = self.bridge.imgmsg_to_cv2(msg)
			# except CvBridgeError, e:
			# 	print e

			# img = cv2.undistort(img,K_left,D_left)

			md5_filename = self.saveMD5Image(image_topic,img)
			# Uncomment the following line to show the progress in the terminal
			parse_utilities.printProgress(count_of_camera_frame, number_of_messages, prefix='Camera Topic Progress:', suffix='Complete', decimals=1, length=50)

			header_time_nanoseconds = repr(msg.header.stamp.secs*10**(9) + msg.header.stamp.nsecs)
			bag_time_nanoseconds = repr(bag_timestamp.secs*10**(9) + bag_timestamp.nsecs)
			# file.write(str(msg.header.seq + 1))
			# file.write(',')
			# file.write(str(parse_utilities.unixTimeToTimeStamp(msg.header.stamp.secs)))
			# file.write(',')
			# file.write(str(msg.header.stamp.secs))
			# file.write(',')
			# file.write(str(msg.header.stamp.nsecs))
			# file.write(',')
			# file.write(header_time_nanoseconds)
			# file.write(',')
			# file.write(bag_time_nanoseconds)
			# file.write(',')
			# file.write(str(md5_filename))
			# file.write('\n')

			count_of_camera_frame += 1

			''' *** '''
			# Create the a row of data for the data frame
			data = self.createCameraDFRow(data, md5_filename, header_time_nanoseconds, bag_time_nanoseconds)
			''' *** '''

		file.close()

		''' *** '''
		# Create a data frame
		df, table_name, db_col_lst = self.createCameraDF(topic, data)
		return df, table_name, db_col_lst
		''' *** '''
	
'''
Changes Made:
	1. Importing psycopg2, rosbag, pandas, and polars libraries
	2. Added 2 new functions:
		a. createCameraDFRow(self, data, md5_filename, header_time_nanoseconds, bag_time_nanoseconds)
		b. createCameraDF(self, topic, data)
	3. Added input varialbes to the above method: bag_file_db_id, to_db, db
	4. Added 4 lines in the above method:
		- Very beginning of the method, right before or after opening the file:
			1. data = []
		- After writing to the file:
			2. data = self.createCameraDFRow(data, md5_filename, header_time_nanoseconds, bag_time_nanoseconds)
		- Final 2 lines:
			c. df = self.createCameraDF(topic, data)
			d. return df
'''