from io import StringIO 
from pathlib import Path
import os
import sys
import shutil
import string
import csv
import time
import datetime
import warnings
import pdb

# import psycopg2
import rosbag
import pandas as pd
import polars as pl
import numpy as np
import hashlib
import velodyne_decoder as vd

import use_database
import parse_utilities

from ouster.sdk import client
from ouster.sdk import bag as ouster_bag
from ouster.sdk.client import SensorInfo
from ouster.sdk.examples.colormaps import normalize

def parse_ouster(pathForRootFolder, PathForCurrentBag, destinationPathForParsedOutputs, hashName_OusterO1, bagFileName, bag_file_db_id, db, to_db):
    to_write = 1

    data = []
    df = pl.DataFrame()

    bagFileSourcePath = pathForRootFolder + '/' + bagFileName
    ousterFolderName = bagFileName.rstrip(".bag")
    ousterFolderPath = destinationPathForParsedOutputs + '/' + ousterFolderName

    '''
    print(f"bagFileName: {bagFileName}")
    print(f"bagFileSourcePath: {bagFileSourcePath}")
    print(f"ousterFolderName: {ousterFolderName}")
    print(f"ousterFolderPath: {ousterFolderPath}")
    '''

    if (to_write == 1):
        try:	#else already exists
            os.makedirs(ousterFolderPath)
        except:
            pass
	
    try:
        bag = rosbag.Bag(bagFileSourcePath)

    except rosbag.ROSBagUnindexedException:
        print(f"The bag file {bagFileName} is unindexed, it won't be parsed")

    except Exception as e:
        print(f"Error running rosbag command: {e}")

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
        # packetSource = ouster_bag.bag_packet_source.BagPacketSource(bagFileSourcePath)
        scanSource = ouster_bag.bag_scan_source.BagScanSource(bagFileSourcePath).single_source(0)
        metadata_scanSource = scanSource.metadata
        if (to_write == 1):
            with open(metadata_path, 'w') as file:
                file.write(metadata_scanSource.to_json_string())
    else:
        print (f"Loading metadata from {metadata_path}")
        if os.path.exists(metadata_path):
            # with open(metadata_path,'r') as json_file:
            # 	metadataClass = SensorInfo(json_file.read())

            # packetSource = ouster_bag.bag_packet_source.BagPacketSource(bagFileSourcePath,meta = [metadataClass])
            scanSource = ouster_bag.bag_scan_source.BagScanSource(bagFileSourcePath, meta = [metadata_path]).single_source(0)
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
        
        if (to_write == 1):
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
        LiDARPacketFileName = ousterFolderPath + '/' + topicName.replace('/', '_slash_') + '.txt'

        if (to_write == 1):
            # Open txt file
            LiDARPacket_File = open(LiDARPacketFileName,"w")
            # Write header to the txt file
            LiDAR_info_header = "LiDAR Frame ID, First Valid Packet Time, Last Packet Time, LiDAR Hashtag"
            LiDARPacket_File.write(LiDAR_info_header + "\n")

        # OusterScanCount = sum(1 for _ in LiDAR_Scans)
        
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

            # parse_utilities.printProgress(idx, 496 - 1, prefix='Progress:', suffix='Complete', decimals=1, length=50)
            
            if (to_write == 1):
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
                        
            file_size = os.path.getsize(PathForCurrentBag + ".bag")

            data.append({
                    'bag_file_db_id' : bag_file_db_id,
                    'ouster_hash': md5_scan,
                    'frame_id' : frame_id,
                    'ouster_hash_root_folder_name': destinationPathForParsedOutputs,
                    'ouster_file_size' : file_size,
                    'first_packet_time' : first_packet_time,
                    'last_packet_time' : last_packet_time,
                    'ply_file' : hash_branch + str(md5_scan) + '.ply',
                    'num_points' : np.shape(xyzirt_reshpaed)[0]
                })

            print(data)
            
            '''
            data.append({
                    'bag_file_db_id' : bag_file_db_id,
                    'ouster_hash': md5_scan,
                    'ouster_range_image_hash': 0,
                    'ouster_signal_image_hash': 0,
                    'ouster_reflective_image_hash': 0,
                    'ouster_nearir_image_hash': 0,
                    'ouster_hash_root_folder_name': pathForRootFolder,
                    'ouster_file_size' : file_size,
                    'ouster_sensor_time' : 0,
                    'ouster_host_time' : 0,
                    'ouster_average_header_time' : 0,
                    'ouster_bag_time' : 0 
                })
            '''
        
        if (to_write == 1):
            LiDARPacket_File.close()

    # Make sure there was no mistake with no data being found
    if (len(data) > 0):
        df = pl.DataFrame(data)   # Create a data frame out of this data

        table_name = "ouster_lidar"

        db_col_lst = ['bag_file_db_id', 'ouster_hash', 'frame_id',
                      'ouster_hash_root_folder_name', 'ouster_file_size',
                      'first_packet_time', 'last_packet_time', 'ply_file', 'num_points']

        '''
        db_col_lst = ['bag_file_db_id', 'ouster_hash', 'ouster_range_image_hash',
                      'ouster_signal_image_hash', 'ouster_reflective_image_hash', 
                      'ouster_nearir_image_hash', 'ouster_hash_root_folder_name',
                      'ouster_file_size', 'ouster_sensor_time', 'ouster_host_time',
                      'ouster_average_header_time', 'ouster_bag_time']
        '''

        # time_lst = ['ouster_sensor_time', 'ouster_host_time', 'ouster_average_header_time', 'ouster_bag_time']

        time_lst = ['first_packet_time', 'last_packet_time']

        # Update each time column to be of type Int64
        for t in time_lst:
            df = df.with_columns(pl.col(t).cast(pl.Int64))

        # Display the data frame
        print(f"\nTotal size of '{topic}' updated data frame: {df.shape}")
        print(f"Displaying the first 3 rows of '{topic}' updated data frame: ")
        print(df.head(3))

        # Write to the database if needed
        if (to_db == 1):
            if table_name != None:
                print("\nWriting to the database...")
                db.df_to_db(table_name, df, db_col_lst)
            else:
                print("Table not in database.")
    
    # If an error occured while trying to make the data frame, print an error and set the df to be an empty Polars data frame
    else:
        print("Error creating dataframe. Dataframe size is 0.")
        df = pl.DataFrame()

    return df
