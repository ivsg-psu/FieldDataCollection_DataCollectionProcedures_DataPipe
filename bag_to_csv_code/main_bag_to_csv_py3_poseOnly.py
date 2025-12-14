'''
This script saves each topic in a bagfile as a csv.

Accepts a filename as an optional argument. Operates on all bagfiles in current directory if no argument provided.

To run the script, just type
python main_bag_to_csv_py3.py -s <sourcePath> -d <destinationPath>

Examples:
py main_bag_to_csv_py3.py -s D:/MappingVanData/RawBags/TestTrack/BaseMap/2024-08-13 -d C:/Users/snb10/Desktop/SourceTree_Repos/IVSG/FeatureExtraction/DataClean/LargeData/ParsedBags/TestTrack/BaseMap/2024_08_13
py main_bag_to_csv_py3.py -s 'D:/MappingVanData/RawBags/TestTrack/Scenario 1.6/2024-09-17' -d 'C:/Users/snb10/Desktop/SourceTree_Repos/IVSG/FeatureExtraction/DataClean/LargeData/ParsedBags/TestTrack/Scenario 1.6/2024_09_17'
py main_bag_to_csv_py3.py -s 'D:/MappingVanData/RawBags/TestTrack/Scenario 1.6/2024-09-17' -d 'C:/Users/snb10/Desktop/SourceTree_Repos/IVSG/FeatureExtraction/DataClean/LargeData/ParsedBags/TestTrack/Scenario 1.6/2024_09_17' -a
py main_bag_to_csv_py3.py -s 'D:/ParseTestInput' -d 'D:/ParseTestOutput' -b mapping_van_2024-07-10-19-35-02_2.bag
py main_bag_to_csv_py3.py -s 'D:/ParseTestInput' -d 'D:/ParseTestOutput' -a

Notes: flag_camera_parsing =1 if you want to parse camera topics into csv.

VERSIONS:
2013 - Created by Nick Speal in May 2013 at McGill University's Aerospace Mechatronics Laboratory www.speal.ca
2021 - Modified by Liming Gao,IVSG
2022-10-24 Edited by Wushuang Bai to write it into a python3 version.
2023-2024 Edited by Xinyu Cao to support ADS project work
2024 - Edited by Sean Brennan and Xinyu Cao to support hash table generation, more flags
2024-10-11 - X. Cao
-- Add a flag to NOT process Ouster in pose-only mode
-- Add a fix to the filesep style to force all the file separators, Windows or otherwise, to go to / even if user enters backslash
-- File locations added as input and output arguments
2024-10-21 - X. Cao
-- Add ROS_Time (time that message arrive to the ros bag), Header_Time to the Velodyne LiDAR fields
2024-11-25 - X. Cao
-- Add another optional input -a, which will parse all bag files in the given sourcePath and subfolders
2024-12-04 - X. Cao
-- Rename Velodyne LiDAR ROS_Time to ROS_Bag_Time, no file structure change
-- Found Ouster LiDAR bags may not have metadata, need to extract metadata from ouster LiDAR and load metadata.json from the script
2024-12-05 - X. Cao
-- Convert Velodyne LiDAR times (bag_time, header_time, host_time, device_time) fomr seconds to nanoseconds
2024-12-11 - X. Cao
-- Save each single LiDAR scan to .PLY file instead of .TXT file
2024-12-21 - X. Cao
-- Add packet_time and column_time for each point in parsed data, E3ach scan has 64 packets, each packet has 16 columns, 
-- but not all packets and columns are valid
-- Both packet_time and column_time are nanoseconds, but packet_time uses UTC_Time, 
-- while column_time uses the internal clock of the sensor (sensor_time)
-- These two times are added to track the time for each single packet or each single point to fix the motion distortion

TO-DO ITEMS:
2024-10-06 - Added by S. Brennan
-- Add a line to copy any README files from source to destination, so README follows bag files into directory above each parsed file directory

'''

import rosbag, sys, csv
import argparse
import time
import string
import os #for file management make directory
import shutil #for file management, copy file
import velodyne_decoder as vd
import numpy as np
import hashlib
from parseCamera import parseCamera
from sensor_msgs.msg import PointCloud2
from ouster.sdk import client
from ouster.sdk import bag as ouster_bag
from ouster.sdk.client import SensorInfo
import matplotlib.pyplot as plt  # type: ignore
from ouster.sdk.examples.colormaps import normalize
from pathlib import Path
import json

###################################################################
#   _    _                  _____      _   _   _                 
#  | |  | |                / ____|    | | | | (_)                
#  | |  | |___  ___ _ __  | (___   ___| |_| |_ _ _ __   __ _ ___ 
#  | |  | / __|/ _ \ '__|  \___ \ / _ \ __| __| | '_ \ / _` / __|
#  | |__| \__ \  __/ |     ____) |  __/ |_| |_| | | | | (_| \__ \
#   \____/|___/\___|_|    |_____/ \___|\__|\__|_|_| |_|\__, |___/
#                                                       __/ |    
#                                                      |___/     
# To create this FIGlet, see:
# https://patorjk.com/software/taag/#p=display&f=Big&t=User%20Settings
###################################################################

# Initialize source and destination path
#  Example: 
# sourcePathForBagFiles = "F:/GIT Files/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/LargeData/2024-09-19" 
# destinationPathForParsedOutputs = "F:/GIT Files/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/LargeData/ParsedData_2024-09-19"
# NOTE: change before running the parse function
# NOTE: In windows, both '\' and '/' work, in Unix/Linux/macOS only '/' is valid
# NOTE: In python, '\\' represents a back slash
# NOTE: if the destination folder does not exist, it will be generated automatically.
# NOTE: the new parse function should take 2~3 inputs:
# sourcePath: Directory to the source folder
# destinationPath: Directory to the destination folder
# bagName: Optional, if is not specified, function will load all bag files in the directories
# Example: python main_bag_to_csv_py3.py -s <sourcePath> -d <destinationPath> (-b <bagFile>) 
# bagFile need to be in the source directory
# NOTE: Added Ouster LiDAR parsing section in the script, the section will be cleaned and functionalized later


argParser = argparse.ArgumentParser(description='Read bag files from source directory and saved parsed files to destination directory.')
argParser.add_argument('-s', '--sourcePath', required=True, help='Directory to the source folder.',type = str)
argParser.add_argument('-d', '--destinationPath', required=True, help='Directory to the destination folder.',type = str)
argParser.add_argument('-b', '--bagName', required=False, help='Bag name of specific file that user wants to parse.')
argParser.add_argument('-a', '--allBagFiles', required=False, action='store_true', help='Parse all bag files in source path and its subfolders.')

# NOTE: The following need to be deleted later
## For Xinyu's computer
# sourcePathForBagFiles = "F:/GIT Files/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/LargeData/Bad Bag Files"
# destinationPathForParsedOutputs = "F:/GIT Files/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/LargeData/Bad Parsed Data"

## For Sean's computer
# sourcePathForBagFiles = "D:/MappingVanData/RawBags/TestTrack/BaseMap/2024-08-05"
# destinationPathForParsedOutputs = "C:/Users/snb10/Desktop/SourceTree_Repos/IVSG/FeatureExtraction/DataClean/LargeData/ParsedBags/TestTrack/BaseMap/2024_08_05"

userInputArgs = argParser.parse_args()
sourcePathForBagFiles = userInputArgs.sourcePath
destinationPathForParsedOutputs = userInputArgs.destinationPath

# Check whether arguments are strings, if not change to string
# if not isinstance(sourcePathForBagFiles, str):
# 	sourcePathForBagFiles = str(sourcePathForBagFiles)

# if not isinstance(destinationPathForParsedOutputs, str):
# 	destinationPathForParsedOutputs = str(destinationPathForParsedOutputs)
# print (sourcePathForBagFiles)
# Initialize hash tree names for Velodyne LiDAR and cameras. A standard format in the team is to put the date onto the hash table name. 
# The hash table is named according to the sourcePathForBagFiles
# Example: sourcePathForBagFiles = "F:/GIT Files/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/LargeData/Bad Bag Files"
# hash trees will be 'hashVelodyne_Bad_Bag_Files' and 'hashCameras_Bad_Bag_Files'
# The hash trees are put as subdirectories in destinationPathForParsedOutputs.

siteFolderName = os.path.basename(sourcePathForBagFiles)
siteFolderName_nonSpace = siteFolderName.replace(" ", "_")
hashName_Velodyne = "hashVelodyne_" + siteFolderName_nonSpace
hashName_Cameras = "hashCameras_" + siteFolderName_nonSpace
hashName_OusterO1 = "hashOusterO1_" + siteFolderName_nonSpace

# NOTE: for bag files that do not contain camera images, no images are produced. But even if flag_parse_camera is set to zero, an image-containing bag will still be parsed for the topics.
# NOTE: setting the flag = 1 for the camera or lidar will produce a hash table
# NOTE: for bag files with camera data, they usually ONLY contain camera data. There are generally no LIDAR, GPS, etc. topics - the only topic will be camera data.
flag_parse_camera = 0
flag_parse_velodyne = 0
flag_parse_sick = 0
flag_parse_ouster = 0

###################################################################
#    _____          _         _____ _             _         _    _               
#   / ____|        | |       / ____| |           | |       | |  | |              
#  | |     ___   __| | ___  | (___ | |_ __ _ _ __| |_ ___  | |__| | ___ _ __ ___ 
#  | |    / _ \ / _` |/ _ \  \___ \| __/ _` | '__| __/ __| |  __  |/ _ \ '__/ _ \
#  | |___| (_) | (_| |  __/  ____) | || (_| | |  | |_\__ \ | |  | |  __/ | |  __/
#   \_____\___/ \__,_|\___| |_____/ \__\__,_|_|   \__|___/ |_|  |_|\___|_|  \___|
# 
# To create this FIGlet, see:
# https://patorjk.com/software/taag/#p=display&f=Big&t=Code%20Starts%20Here
###################################################################

###########################################################################
#   _____      _   _        _____ _               _    
#  |  __ \    | | | |      / ____| |             | |   
#  | |__) |_ _| |_| |__   | |    | |__   ___  ___| | __
#  |  ___/ _` | __| '_ \  | |    | '_ \ / _ \/ __| |/ /
#  | |  | (_| | |_| | | | | |____| | | |  __/ (__|   < 
#  |_|   \__,_|\__|_| |_|  \_____|_| |_|\___|\___|_|\_\              
# To create this FIGlet, see:
# https://patorjk.com/software/taag/#p=display&f=Big&t=Path%20Check
###################################################################

# For source path, we want to check whether the path exist
if not os.path.exists(sourcePathForBagFiles):
	print ('Warning: The source path does not exist or has incorrect file separators.')
# After than check whether there are '\' used in the string, if exists, we should replace '\' with '/'

if '\\' in sourcePathForBagFiles:
	print ('Fixing file separators in sourcePath.')
	sourcePathForBagFiles = sourcePathForBagFiles.replace('\\','/')

# Check the path again after the replacement
if not os.path.exists(sourcePathForBagFiles):
	raise FileNotFoundError('The source path does not exist')

# For destination path, we just want to make sure only '/' is used
if '\\' in destinationPathForParsedOutputs:
	print ('Fixing file separators in destinationPath.')
	destinationPathForParsedOutputs = destinationPathForParsedOutputs.replace('\\','/')



#verify correct input arguments: 5 or 6
if (len(sys.argv) > 8):
	print ("invalid number of arguments:   " + str(len(sys.argv)))
	print ("should be 5: main_bag_to_csv_py3.py -s sourcePath -d destinationPath")
	print ("or 6 : main_bag_to_csv_py3.py -s sourcePath -d destinationPath -a")
	print ("or 7 : main_bag_to_csv_py3.py -s sourcePath -d destinationPath -b bagName")
	sys.exit(1)
elif (len(sys.argv) == 7):
	inputBagName = userInputArgs.bagName
	if not isinstance(inputBagName, str):
		inputBagName = str(inputBagName)
	listOfBagFiles = [inputBagName]
	numberOfFiles = "1"
	print ("reading only 1 bagfile: " + str(listOfBagFiles[0]))
elif (len(sys.argv) == 6):
	root_path = Path(sourcePathForBagFiles)
	listOfBagFiles = [str(p.relative_to(root_path)) for p in root_path.rglob("*") if p.suffix in [".bag", ".active"]]
	numberOfFiles = str(len(listOfBagFiles))
	print ("reading all " + numberOfFiles + " bagfiles in current directory: \n")
	for f in listOfBagFiles:
		print (f)
	print ("\n press ctrl+c in the next 5 seconds to cancel \n")
	time.sleep(5)

elif (len(sys.argv) == 5):
	listOfBagFiles = [f for f in os.listdir(sourcePathForBagFiles) if f.endswith(".bag") or f.endswith(".active")]	#get list of only bag files in current dir.
	numberOfFiles = str(len(listOfBagFiles))
	print ("reading all " + numberOfFiles + " bagfiles in current directory: \n")
	for f in listOfBagFiles:
		print (f)
	print ("\n press ctrl+c in the next 5 seconds to cancel \n")
	time.sleep(5)
else:
	print ("bad argument(s): " + str(sys.argv))	#shouldnt really come up
	sys.exit(1)



# Choose timer to use
# if sys.platform.startswith('win'):
# 	default_timer = time.clock
# else:
default_timer = time.time

total_start = default_timer()


count_of_bagFile = 0
for bagFile in listOfBagFiles:
	count_of_bagFile += 1
	start = default_timer()
	print ("reading file " + str(count_of_bagFile) + " of  " + numberOfFiles + ": " + bagFile + "...")

	# If the bagFile contains the string "velodynePoints", we do not want to parse the file.
	# These are bagFiles only collected for playback to check data on the mappingVan during data collection.
	# They contain pointCloud data from Velodyne, but we do not want to use these because they produce VERY large output files.
	flag_unindexed_bag = 0
	if "velodynePoints"  and "Ouster" not in bagFile:
		# bagFilePath = os.path.join(sourcePathForBagFiles,bagFile)
		bagFilePath = sourcePathForBagFiles + '/' + bagFile
		try:
			bag = rosbag.Bag(bagFilePath,'r')
		except rosbag.ROSBagUnindexedException:
			print(f"The bag file {bagFile} is unindexed, it won't be parsed")
			continue
		except Exception as e:
			print(f"Error running rosbag command: {e}")
			continue

		bagContents = bag.read_messages()
		bagName = bag.filename

		#create a new directory
		# folder = string.rstrip(bagName, ".bag")
		bagFolder = bagFile.rstrip(".bag")
		PathForCurrentBag = destinationPathForParsedOutputs + '/' + bagFolder
	
		try:	#else already exists
			os.makedirs(PathForCurrentBag)
		except:
			pass
			# print ('this folder already exists:', PathForCurrentBag)
		#shutil.copyfile(bagName, folder + '/' + bagName)


		#get list of topics from the bag
		listOfTopics = []
		for topic, msg, t in bagContents:
			if topic not in listOfTopics:
				listOfTopics.append(topic)

		
		PC = parseCamera(destinationPathForParsedOutputs,bag,hashName_Cameras)
		if flag_parse_camera == 1:
			if '/rear_left_camera/image_rect_color/compressed' in listOfTopics:
				time_start = time.time()
				rear_left_image_topic = '/rear_left_camera/image_rect_color/compressed'
				OutputFileName = PathForCurrentBag + '/' + rear_left_image_topic.replace('/', '_slash_') + '.txt'
				PC.parseCamera(rear_left_image_topic, OutputFileName)
				listOfTopics.remove(rear_left_image_topic)
				time_end = time.time()
				time_elpased = time_end - time_start
				print("'rear_left_camera' has been parsed.")
				print("Elpased time is " + str(time_elpased))
			if '/rear_center_camera/image_rect_color/compressed' in listOfTopics:
				time_start = time.time()
				rear_center_image_topic = '/rear_center_camera/image_rect_color/compressed'
				OutputFileName = PathForCurrentBag + '/' + rear_center_image_topic.replace('/', '_slash_') + '.txt'
				PC.parseCamera(rear_center_image_topic, OutputFileName)
				listOfTopics.remove(rear_center_image_topic)
				print("'rear_center_camera' has been parsed.")
				time_end = time.time()
				time_elpased = time_end - time_start
			if '/rear_right_camera/image_rect_color/compressed' in listOfTopics:
				time_start = time.time()
				rear_right_image_topic = '/rear_right_camera/image_rect_color/compressed'
				OutputFileName = PathForCurrentBag + '/' + rear_right_image_topic.replace('/', '_slash_') + '.txt'
				PC.parseCamera(rear_right_image_topic, OutputFileName)
				listOfTopics.remove(rear_right_image_topic)
				print("'rear_right_camera' has been parsed.")
				time_end = time.time()
				time_elpased = time_end - time_start

			if '/front_left_camera/image_rect_color/compressed' in listOfTopics:
				front_left_image_topic = '/front_left_camera/image_rect_color/compressed'
				OutputFileName = PathForCurrentBag + '/' + front_left_image_topic.replace('/', '_slash_') + '.txt'
				PC.parseCamera(front_left_image_topic, OutputFileName)
				listOfTopics.remove(front_left_image_topic)
				print("'front_left_camera' has been parsed.")
			if '/front_center_camera/image_rect_color/compressed' in listOfTopics:
				front_center_image_topic = '/front_center_camera/image_rect_color/compressed'
				OutputFileName = PathForCurrentBag + '/' + front_center_image_topic.replace('/', '_slash_') + '.txt'
				PC.parseCamera(front_center_image_topic, OutputFileName)
				listOfTopics.remove(front_center_image_topic)
				print("'front_center_camera' has been parsed.")
			if '/front_right_camera/image_rect_color/compressed' in listOfTopics:
				front_right_image_topic = '/front_right_camera/image_rect_color/compressed'
				OutputFileName = PathForCurrentBag + '/' + front_right_image_topic.replace('/', '_slash_') + '.txt'
				PC.parseCamera(front_right_image_topic, OutputFileName)
				listOfTopics.remove(front_right_image_topic)
				print("'front_right_camera' has been parsed.")

			if '/rear_left_camera/image_color' in listOfTopics:
				listOfTopics.remove('/rear_left_camera/image_color')
				print("'rear_left_camera' will not be parsed.")
			if '/rear_center_camera/image_color' in listOfTopics:
				listOfTopics.remove('/rear_center_camera/image_color')
				print("'rear_center_camera' will not be parsed.")
			if '/rear_right_camera/image_color' in listOfTopics:
				listOfTopics.remove('/rear_right_camera/image_color')
				print("'rear_right_camera' will not be parsed.")

			if '/rear_left_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_left_camera/image_color/compressed')
				print("'rear_left_camera' will not be parsed.")
			if '/rear_center_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_center_camera/image_color/compressed')
				print("'rear_center_camera' will not be parsed.")
			if '/rear_right_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_right_camera/image_color/compressed')
				print("'rear_right_camera' will not be parsed.")
		else:
			if '/rear_left_camera/image_rect_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_left_camera/image_rect_color/compressed')
				print("'rear_left_camera' will not be parsed.")
			if '/rear_center_camera/image_rect_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_center_camera/image_rect_color/compressed')
				print("'rear_center_camera' will not be parsed.")
			if '/rear_right_camera/image_rect_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_right_camera/image_rect_color/compressed')
				print("'rear_right_camera' will not be parsed.")
			if '/front_left_camera/image_rect_color/compressed' in listOfTopics:
				listOfTopics.remove('/front_left_camera/image_rect_color/compressed')
				print("'front_left_camera' will not be parsed.")
			if '/front_center_camera/image_rect_color/compressed' in listOfTopics:
				listOfTopics.remove('/front_center_camera/image_rect_color/compressed')
				print("'front_center_camera' will not be parsed.")
			if '/front_right_camera/image_rect_color/compressed' in listOfTopics:
				listOfTopics.remove('/front_right_camera/image_rect_color/compressed')
				print("'front_right_camera' will not be parsed.")

			if '/rear_left_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_left_camera/image_color/compressed')
				print("'rear_left_camera' will not be parsed.")
			if '/rear_center_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_center_camera/image_color/compressed')
				print("'rear_center_camera' will not be parsed.")
			if '/rear_right_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/rear_right_camera/image_color/compressed')
				print("'rear_right_camera' will not be parsed.")

			if '/front_left_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/front_left_camera/image_color/compressed')
				print("'front_left_camera' will not be parsed.")
			if '/front_center_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/front_center_camera/image_color/compressed')
				print("'front_center_camera' will not be parsed.")
			if '/front_right_camera/image_color/compressed' in listOfTopics:
				listOfTopics.remove('/front_right_camera/image_color/compressed')
				print("'front_right_camera' will not be parsed.")




		print ('For "{}", these {} topics will be parsed: \n{}'.format(bagFile,len(listOfTopics),listOfTopics))
		
		for topicName in listOfTopics:
			# Create a new CSV file for each topic except LiDARs and cameras

	
			if topicName == '/sick_lms500/scan' or topicName == '/velodyne_points' or topicName == '/velodyne_packets' or 'Ouster' in topicName: #convert this topic into txt file 
				filename = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.txt'
				
			else:
			
				filename = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.csv'

			if not os.path.exists(filename):

				if topicName == '/sick_lms_5xx/scan': #convert this topic into txt file 
					if flag_parse_sick == 1:
						OutputFileName = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.txt'
						File = open(OutputFileName,"w")
						#print("Parsing Laser...")
						for topic, msg, t in bag.read_messages(topicName):
						#	print msg
							File.write(str(msg.header.seq))
							File.write(',')
							File.write(str(msg.header.stamp.secs))
							File.write(',')
							File.write(str(msg.header.stamp.nsecs))
							File.write(',')
							File.write(str(msg.angle_min))
							File.write(',')
							File.write(str(msg.angle_max))
							File.write(',')
							File.write(str(msg.angle_increment))
							File.write(',')
							File.write(str(msg.time_increment))
							File.write(',')
							File.write(str(msg.scan_time))
							File.write(',')
							File.write(str(msg.range_min))
							File.write(',')
							File.write(str(msg.range_max))
							File.write(',')
							File.write(', '.join(map(str,msg.ranges))) # This removes the leading and lagging parenthese from this message
							File.write(',')
							File.write(', '.join(map(str,msg.intensities))) # This removes the leading and lagging parenthese from this message
							File.write('\n')

						File.close()
					else:
						print ('Sick LiDAR will not be parsed')
				# Mose bag files do not contain /velodyne_points topics, keeping here just in case some old bag files need to be parsed
				elif topicName == '/velodyne_points':
					if flag_parse_velodyne==1:
						OutputFileName = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.txt'
						File = open(OutputFileName,"w")
						VelodyneInfoFile = PathForCurrentBag +'/'+'velodyne_info.txt'
						InfoFile = open(VelodyneInfoFile,'w')
						for topic, msg, t in bag.read_messages(topicName):
							InfoFile.write(', '.join(map(str,msg.fields))) # This removes the leading and lagging parenthese from this message
							InfoFile.write('\n')
							File.write(str(msg.header.seq))
							File.write(',')
							File.write(str(msg.header.stamp.secs))
							File.write(',')
							File.write(str(msg.header.stamp.nsecs))
							File.write(',')
							File.write(str(msg.height))
							File.write(',')
							File.write(str(msg.width))
							File.write(',')
							File.write(str(msg.is_bigendian))
							File.write(',')
							File.write(str(msg.point_step))
							File.write(',')
							File.write(str(msg.row_step))
							File.write(',')
							File.write(str(msg.is_dense))
							File.write('\n')

						File.close()
						InfoFile.close()
					else:
						print ('Velodyne LiDAR velodyne_points topic will not be parsed')

				elif topicName == '/velodyne_packets':
					if flag_parse_velodyne==1:
						count_of_LiDARScan = 1
						velodyne_folder = destinationPathForParsedOutputs + '/' + hashName_Velodyne
						config = vd.Config(model = vd.Model.PuckHiRes)
						try:	#else already exists
							os.makedirs(velodyne_folder)
						except:
							pass
							# print ('this folder already exists:', velodyne_folder)
						lidar_topics = [topicName]
						cloud_arrays = []
						OutputFileName = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.txt'
						# Open txt file
						File = open(OutputFileName,"w")
						# Write header to the txt file
						# Header_Time is the time when the message is generated, ROS_Bag_Time is the timestamp when the message is recorded in the bags
						LiDAR_info_header = "LiDAR Index, ROS_Bag_Time (nanoseconds), Header_Time (nanoseconds), Host Time (nanoseconds), Device Time (nanoseconds), LiDAR Hashtag"
						File.write(LiDAR_info_header + "\n")
						LiDAR_Bag_Time = []
						LiDAR_Header_Time = []
						for topic, msg, bag_timestamp in bag.read_messages(topicName):
							headerTime = msg.header.stamp.secs*10**(9) + msg.header.stamp.nsecs
							LiDAR_Bag_Time.append(bag_timestamp.secs*10**(9) + bag_timestamp.nsecs)
							LiDAR_Header_Time.append(headerTime)
						for stamp, points, topic, scan_frame_id in vd.read_bag(bagName, config, topicName, as_pcl_structs = True):
			
							points = np.ascontiguousarray(points)
							num_points = np.shape(points)[0]
							md5_scan = hashlib.md5(points).hexdigest()
							hash_branch = velodyne_folder + '/' + md5_scan[0:2] + '/' + md5_scan[2:4] + '/'
							points_file = hash_branch + str(md5_scan) + '.txt'
							ply_file =  hash_branch + str(md5_scan) + '.ply'
							try:
								os.makedirs(hash_branch)
							except:
								pass
								# print ('this folder already exists:', hash_branch)
							File.write(str(count_of_LiDARScan))
							File.write(',')
							File.write(str(LiDAR_Bag_Time[count_of_LiDARScan-1]))
							File.write(',')
							File.write(str(LiDAR_Header_Time[count_of_LiDARScan-1]))
							File.write(',')
							File.write(str(int(stamp.host*10**(9))))
							File.write(',')
							File.write(str(int(stamp.device*10**(9))))
							File.write(',')
							File.write(str(md5_scan))
							File.write('\n')
							with open(ply_file, 'w') as f:
								f.write(f"""ply
									format ascii 1.0
									element vertex {num_points}
									property float x
									property float y
									property float z
									property float intensity
									property float time
									property int column
									property int ring
									property int return_type
									end_header
									""")
								np.savetxt(f, points, fmt ="%.8f %.8f %.8f %.8f %.8f %d %d %d")
							# np.savetxt(points_file, points, delimiter=',')

							# cloud_arrays.append(points)

							count_of_LiDARScan += 1
							
						File.close()
					else:
						print ('Velodyne LiDAR will not be parsed')

				elif 'Ouster' in topicName: # Need to check the name of the Ouster topic, will change later
					if flag_parse_ouster == 1:
						print ('Parsing function will be added later')
					else:
						print ('Ouster LiDAR will not be parsed')
				else:
					with open(filename, 'w+') as csvfile:
						filewriter = csv.writer(csvfile, delimiter = ',')
						firstIteration = True	#allows header row

						for subtopic, msg, t in bag.read_messages(topicName):	# for each instant in time that has data for topicName
							#parse data from this instant, which is of the form of multiple lines of "Name: value\n"

							msgString = str(msg)

							# msgList = string.split(msgString, '\n')
							msgList = msgString.split('\n')
							instantaneousListOfData = []
							for nameValuePair in msgList:
								# splitPair = string.split(nameValuePair, ':')
								splitPair = nameValuePair.split(':')
								for i in range(len(splitPair)):	#should be 0 to 1
									# splitPair[i] = string.strip(splitPair[i])
									splitPair[i] = splitPair[i].strip()
								instantaneousListOfData.append(splitPair)
							# print (instantaneousListOfData,t.secs,t.nsecs)
							#write the first row from the first element of each pair
							if firstIteration:	# header
								headers = ["rosbagTimestamp"]	#first column header
								for pair in instantaneousListOfData:
									headers.append(pair[0])
								filewriter.writerow(headers)
								firstIteration = False
							# write the value from each pair to the file
							values = [str(t)]	#first column will have rosbag timestamp
							for pair in instantaneousListOfData:
								if len(pair) > 1:
									values.append(pair[1])
							filewriter.writerow(values)
			else:
				print ('This file has already existed:', filename)

		bag.close()



		finish = default_timer()

		print ("Finished " + bagFile + " in " + str(finish-start) + " seconds.\n")

	elif "OusterO1" in bagFile and "Images" not in bagFile:
		if flag_parse_ouster:
			print ("Start parsing OusterO1 LiDAR Packets")

			bagFilePath = sourcePathForBagFiles + '/' + bagFile
			bagFolder = bagFile.rstrip(".bag")
			PathForCurrentBag = destinationPathForParsedOutputs + '/' + bagFolder
			try:	#else already exists
				os.makedirs(PathForCurrentBag)
			except:
				pass
	
			try:
				bag = rosbag.Bag(bagFilePath)
			except rosbag.ROSBagUnindexedException:
				print(f"The bag file {bagFile} is unindexed, it won't be parsed")
				continue
			except Exception as e:
				print(f"Error running rosbag command: {e}")
				continue

			bagContents = bag.read_messages()
			listOfTopics = []
			for topic, msg, t in bagContents:
				if topic not in listOfTopics:
					listOfTopics.append(topic)		
			current_path = os.getcwd()
			parent_folder = os.path.dirname(current_path)
			doc_folder = 'Documents'
			metadata_folder = 'LiDAR_Metadata'
			json_file_name = 'OusterO1_metadata.json'
			metadata_path = os.path.join(parent_folder,doc_folder, metadata_folder, json_file_name)
			if '/ousterO1/metadata' in listOfTopics:
				# packetSource = ouster_bag.bag_packet_source.BagPacketSource(bagFilePath)
				scanSource = ouster_bag.bag_scan_source.BagScanSource(bagFilePath).single_source(0)
				metadata_scanSource = scanSource.metadata
				with open(metadata_path, 'w') as file:
					file.write(metadata_scanSource.to_json_string())
			else:
				print (f"Loading metadata from {metadata_path}")
				if os.path.exists(metadata_path):
					# with open(metadata_path,'r') as json_file:
					# 	metadataClass = SensorInfo(json_file.read())

					# packetSource = ouster_bag.bag_packet_source.BagPacketSource(bagFilePath,meta = [metadataClass])
					scanSource = ouster_bag.bag_scan_source.BagScanSource(bagFilePath, meta = [metadata_path]).single_source(0)
					metadata_scanSource = scanSource.metadata
				else:
					print(f'{metadata_path} does not exist')
				
						
			# metadata_packetSource = packetSource.metadata
			# packet_format = client.PacketFormat(metadata_scanSource)	
			# Will delete later, since imu data are also recorded in the core bag file
			# if '/ousterO1/imu_packets' in listOfTopics:
			# 	topicName = '/ousterO1/imu_packets'
			# 	filename = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.csv'
			# 	with open(filename, 'w+') as csvfile:
			# 		filewriter = csv.writer(csvfile, delimiter = ',')
			# 		fileheader = ['secs','nsecs','acceleration_x','acceleration_y','acceleration_z','angular_velocity_x','angular_velocity_y','angular_velocity_z']
			# 		filewriter.writerow(fileheader)
			# 		for subtopic, packet,t in bag.read_messages('/ousterO1/imu_packets'):
			# 			ax = packet_format.imu_la_x(packet.buf)
			# 			ay = packet_format.imu_la_y(packet.buf)
			# 			az = packet_format.imu_la_z(packet.buf)
			# 			wx = packet_format.imu_av_x(packet.buf)
			# 			wy = packet_format.imu_av_y(packet.buf)
			# 			wz = packet_format.imu_av_z(packet.buf)
			# 			time_secs = t.secs
			# 			time_nsecs =t.nsecs
			# 			current_row = [time_secs, time_nsecs, ax, ay, az, wx, wy, wz]
			# 			filewriter.writerow(current_row)
			if '/ousterO1/lidar_packets' in listOfTopics:
				topicName = '/ousterO1/lidar_packets'
				LiDAR_Scans = iter(scanSource)		
				# precompute xyzlut to save computation in a loop
				xyzlut = client.XYZLut(metadata_scanSource)
			

				ousterO1_folder = destinationPathForParsedOutputs + '/' + hashName_OusterO1
				try:	#else already exists
					os.makedirs(ousterO1_folder)
				except:
					pass
				
				# LiDAR_Bag_Time = []
				# packet_count = 0
				# for topic, msg, t in bag.read_messages(topics = '/ousterO1/lidar_packets'):
				# 	if (packet_count+1) % 64 == 0:
				# 		LiDAR_Bag_Time.append(t.secs + t.nsecs*10**(-9))
					
				# 	packet_count += 1
				# print (len(LiDAR_Bag_Time))		
				# print (packet_count/64)
				LiDARPacketFileName = PathForCurrentBag + '/' + topicName.replace('/', '_slash_') + '.txt'
				# Open txt file
				LiDARPacket_File = open(LiDARPacketFileName,"w")
				# Write header to the txt file
				LiDAR_info_header = "LiDAR Frame ID, First Valid Packet Time, Last Packet Time, LiDAR Hashtag"
				LiDARPacket_File.write(LiDAR_info_header + "\n")
				# Each scan has 64 packets, and each packet has 16 columns, but not all packets or columns are valid
				for idx, scan in enumerate(LiDAR_Scans):
					xyz = xyzlut(scan.field(client.ChanField.RANGE))
					reflectivity = scan.field(client.ChanField.REFLECTIVITY)
					reflectivity_3d = reflectivity[..., np.newaxis]
					num_rings = xyz.shape[0]
					
					# NOTE: ring_ids might not be correct
					ring_ids = np.arange(num_rings).reshape(-1, 1) * np.ones((1, xyz.shape[1]), dtype=int) 
					ring_ids_3d = ring_ids[..., np.newaxis]
					
					# NOTE: This can be ROS_Time or Pulse in Time, depending on setting in launch file
					first_packet_time = scan.get_first_valid_packet_timestamp()
					packet_times = scan.packet_timestamp
					packet_times_array = np.expand_dims(packet_times, axis=1)
					packet_times_3d = np.tile(packet_times_array, (num_rings, 16, 1))


					last_packet_time = packet_times[-1]
					# print (packet_times, first_packet_time, last_packet_time)
					# if idx == 2:
					# 	sys.exit()
					column_times = scan.timestamp
					column_times_array = np.expand_dims(column_times, axis=1)
					column_times_3d = np.tile(column_times_array, (num_rings, 1, 1))

					# X, Y, Z, intensity, ring_id, packet_time for each point, column_time for each point
					# column_time hash nanosecond level resolution and 10 nanosecond increment, but the timeline is incorrect 
					xyzirt = np.concatenate((xyz, reflectivity_3d,ring_ids_3d,packet_times_3d,column_times_3d),axis = -1)
					num_columns = xyzirt.shape[2]
					xyzirt_reshpaed = xyzirt.reshape(-1, num_columns)	
			
					xyzirt_contiguous = np.ascontiguousarray(xyzirt_reshpaed)
					md5_scan = hashlib.md5(xyzirt_contiguous).hexdigest()
					frame_id = scan.frame_id
					hash_branch = ousterO1_folder + '/' + md5_scan[0:2] + '/' + md5_scan[2:4] + '/'
					points_file = hash_branch + str(md5_scan) + '.txt'
					# NOTE: To do save franem_id, packet_time, md5_scan
					try:
						os.makedirs(hash_branch)
					except:
						pass
					LiDARPacket_File.write(str(frame_id))
					LiDARPacket_File.write(',')
					LiDARPacket_File.write(str(first_packet_time))
					LiDARPacket_File.write(',')
					LiDARPacket_File.write(str(last_packet_time))
					LiDARPacket_File.write(',')
					LiDARPacket_File.write(str(md5_scan))
					LiDARPacket_File.write('\n')
					ply_file = hash_branch + str(md5_scan) + '.ply'
					num_points = np.shape(xyzirt_reshpaed)[0]
					with open(ply_file, 'w') as f:
						f.write(f"""ply
								format ascii 1.0
								element vertex {num_points}
								property float x
								property float y
								property float z
								property float intensity
								property int ringID
								property int packet_time
								property int column_time
								end_header
								""")
						np.savetxt(f, xyzirt_reshpaed, fmt ="%.8f %.8f %.8f %.4f %d %d %d")
					# np.savetxt(points_file, xyzir_reshpaed, delimiter=',')
	
				LiDARPacket_File.close()

			

			
		else:
			print ("Ouster LiDAR won't be parsed")

print ("Done reading all " + numberOfFiles + " bag files.")

total_finish = default_timer()

print ("Total time: " + str(total_finish-total_start) + " seconds.")
