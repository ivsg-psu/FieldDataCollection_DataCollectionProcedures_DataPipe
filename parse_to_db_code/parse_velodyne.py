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

def parse_velodyne(pathForRootFolder, PathForCurrentBag, destinationPathForParsedOutputs, hashName_Velodyne, topicName, bag, bag_file_db_id, db, to_db):
    to_write = 0
    data = []
    df = pl.DataFrame()

    count_of_LiDARScan = 1
    number_of_messages = bag.get_message_count(topic_filters=topicName)

    velodyne_folder = destinationPathForParsedOutputs + '/' + hashName_Velodyne

    config = vd.Config(model = vd.Model.PuckHiRes)
    if (to_write == 1):
        try:	#else already exists
            os.makedirs(velodyne_folder)
        except:
            pass
            # print ('this folder already exists:', velodyne_folder)
    lidar_topics = [topicName]
    cloud_arrays = []

    bag_name = bag.filename.rstrip(".bag").split("/")[-1]
    OutputFileName = destinationPathForParsedOutputs + '/' + bag_name + '/' + topicName.replace('/', '_slash_') + '.txt'

    # print(OutputFileName)
    # print(destinationPathForParsedOutputs)

    # Open txt file
    if (to_write == 1):
        File = open(OutputFileName,"w")
    # Write header to the txt file
    # Header_Time is the time when the message is generated, ROS_Bag_Time is the timestamp when the message is recorded in the bags
    LiDAR_info_header = "LiDAR Index, ROS_Bag_Time (nanoseconds), Header_Time (nanoseconds), Host Time (nanoseconds), Device Time (nanoseconds), LiDAR Hashtag"
    if (to_write == 1):
        File.write(LiDAR_info_header + "\n")

    LiDAR_Bag_Time = []
    LiDAR_Header_Time = []
    for topic, msg, bag_timestamp in bag.read_messages(topicName):
        headerTime = msg.header.stamp.secs*10**(9) + msg.header.stamp.nsecs
        LiDAR_Bag_Time.append(bag_timestamp.secs*10**(9) + bag_timestamp.nsecs)
        LiDAR_Header_Time.append(headerTime)
    for stamp, points, topic, scan_frame_id in vd.read_bag(PathForCurrentBag, config, topicName, as_pcl_structs = True):

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

        parse_utilities.printProgress(count_of_LiDARScan, number_of_messages, prefix='Velodyne Packet Progress:', suffix='Complete', decimals=1, length=50)

        velodyne_sensor_time = int(stamp.device*10**(9))
        velodyne_host_time = int(stamp.host*10**(9))
        velodyne_average_header_time = LiDAR_Header_Time[count_of_LiDARScan-1]
        velodyne_bag_time = LiDAR_Bag_Time[count_of_LiDARScan-1]

        if (to_write == 1):
            File.write(str(count_of_LiDARScan))
            File.write(',')
            File.write(str(velodyne_bag_time))
            File.write(',')
            File.write(str(velodyne_average_header_time))
            File.write(',')
            File.write(str(velodyne_host_time))
            File.write(',')
            File.write(str(velodyne_sensor_time))
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

        file_size = os.path.getsize(PathForCurrentBag)

        data.append({
                'bag_file_db_id' : bag_file_db_id,
				'velodyne_hash': md5_scan,
				'velodyne_hash_root_folder_name': destinationPathForParsedOutputs,
				'velodyne_file_size' : file_size,
                'velodyne_sensor_time' : velodyne_sensor_time,
                'velodyne_host_time' : velodyne_host_time,
                'velodyne_average_header_time' : velodyne_average_header_time,
				'velodyne_bag_time' : velodyne_bag_time 
			})

        count_of_LiDARScan += 1

    if (to_write == 1):    
        File.close()

    # Make sure there was no mistake with no data being found
    if (len(data) > 0):
        df = pl.DataFrame(data)   # Create a data frame out of this data

        table_name = "velodyne_lidar"

        db_col_lst = ['bag_file_db_id', 'velodyne_hash', 'velodyne_hash_root_folder_name',
                      'velodyne_file_size', 'velodyne_sensor_time', 'velodyne_host_time',
                      'velodyne_average_header_time', 'velodyne_bag_time']

        time_lst = ['velodyne_sensor_time', 'velodyne_host_time', 'velodyne_average_header_time', 'velodyne_bag_time']

        # Update each time column to be of type Int64
        for t in time_lst:
            df = df.with_columns(pl.col(t).cast(pl.Int64))

        # Display the data frame
        # display_df = 0
        # if (display_df == 1):
        #     print(f"\nTotal size of '{topic}' updated data frame: {df.shape}")
        #     print(f"Displaying the first 3 rows of '{topic}' updated data frame: ")
        #     print(df.head(3))

        pd_df = df.to_pandas()
        pd_df_byte = pd_df.memory_usage(deep = True).sum()
        pd_df_mem = pd_df_byte / (1024 * 1024)


        # Write to the database if needed
        # if (to_db == 1):
        #     if table_name != None:
        #         # print("\nWriting to the database...")
        #         db_start_time = time.time()
        #         db.df_to_db(table_name, df, db_col_lst)
        #         db_end_time = time.time() 

        #         db_time = round((db_end_time - db_start_time), 4)
        #         db_throughput = round((pd_df_mem / db_time), 4)
        #         print(f"\nDF Size (MB): {pd_df_mem}, DF Throughput (MB/sec): {db_throughput}, DB Runtime (sec): {db_time}\n")

        #     else:
        #         print("Table not in database.")

    
    # If an error occured while trying to make the data frame, print an error and set the df to be an empty Polars data frame
    else:
        print("Error creating dataframe.")
        df = pl.DataFrame()
        
    return df, table_name, db_col_lst