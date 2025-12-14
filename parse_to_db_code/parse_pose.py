'''
Python 3.10.1 and Python 3.12.3

Written by Sadie Duncan at IVSG between Summer 2024 - Spring 2025
Supervised by Professor Sean Brennan

Purpose:
    The purpose of this script is to parse pose data (not including the velodyne or
    ouster packets).

Usage:
    Called from the parse_and_insert_v2.py script.

Method(s):
    - display_df(topic, df, debug_flag = False, debug_ouster_imu_flag = False)
        - Display the first three rows of a data frame.
    - parse_pose_topics(bag, topic, subtopics, bag_file_db_id, to_db, db)
        - Parse pose data from a specific bag given a topic and subtopics. 
'''
from io import StringIO 
from pathlib import Path
import os
import sys
import shutil
import string
import csv
import time
import datetime
import textwrap
import warnings
import pdb

# import psycopg2
import rosbag
import pandas as pd
import polars as pl
import numpy as np

from get_table_info import get_table_info
from update_df import update_df

'''
Display the first three rows of a data frame
'''
def display_df(topic, df, debug_flag = False, debug_ouster_imu_flag = False):
    # Strings to print
    size_string = f"\nTotal size of '{topic}' data frame: {df.shape}"
    display_string = f"Displaying the first 3 rows of '{topic}' data frame: "

    # Add additional information depending on whether you're printing before or after updating the data frame
    if (debug_flag == True):
        size_string = size_string.replace(":", " before updating:")
        display_string = display_string.replace(":", " before updating:")

    # Print the strings and data frame
    print(size_string)
    print(display_string)
    print(df.head(3))

    # For additional information, print the columns
    if (debug_flag == True):
        print(df.columns)

    # For the ousterO1/imu topic, print even more additional information
    if (debug_ouster_imu_flag == True):
        df.select("orientation_covariance").glimpse()

''' 
Parse pose data from a specific bag given a topic and subtopics
'''
def parse_pose_topics(bag, topic, subtopics, bag_file_db_id, to_db, db):
    bag_name = bag.filename   # Store the specific bag name

    # Create an empty data frame, table_name and db_col_lst so you'll have something to return regardless
    df = pl.DataFrame()
    table_name = ""
    db_col_lst = []

    # For debugging, choose 1 specific topic to test
    selected_topic = "/ousterO1/imu"

    # Skipping the sick_lms_5xx and velodyne/ouster packet topics
    if topic == "/sick_lms_5xx/scan":
        print("Sick LiDAR will not be parsed.\n")

    elif topic == "/velodyne_packets":
        print("Velodyne Packets not handled here.\n")

    elif topic == "/ouster_packets":
        print("Ouster Packets not handled here.\n")

    # elif ("gst" in topic):
    # elif topic == selected_topic:   # For debugging, selected_topic is chosen above
    else:
        # The table and topic name do not match - use the following to align the naming
        # Handle the ousterO1/imu topic specifically
        if (topic == "/ousterO1/imu"):
            table_name = "oustero1_imu"
        else:
            table_name = topic.replace("/", "")   # Get rid the of "/" in the naming
            table_name = table_name.lower()       # Make sure the name is all lowercase
        
        # Handle the parse_encoder and parse_trigger topics
        if ("parse" in table_name):
            table_name = table_name.replace("parse", "")   # Get rid of the "parse" in the name (if there)

        table_name, mapping_dict, db_col_lst = get_table_info(table_name)   # Get information about the corresponding table
        
        subtopic_dict = {old_name : new_name[0] for old_name, new_name in mapping_dict.items()}
        subtopic_lst = list(subtopic_dict.values())

        '''
        subtopic_print_txt = f"\tFor {topic}, these {len(subtopic_lst)} subtopics will be parsed: {subtopic_lst}"
        wrapped_txt = textwrap.fill(subtopic_print_txt, width = 120, subsequent_indent = "\t")
        print(wrapped_txt)
        '''

        # The following array of data contains "rows" of dictionaries.
        # This data array is then transformed into a polars dataframe
        data = []

        '''

        # Expand the "header" subtopic into more columns
        if "header" in subtopics:
            subtopics.remove("header")
            
        header_lst = ["rosbagTimestamp", "written_to_bag_time", "ros_header_seconds", "ros_header_nanoseconds",
                      "header", "seq", "stamp", "frame_id"]
        
        # There is a special scenario for the /ousterO1/imu topic
        if (topic == '/ousterO1/imu'):
            subtopics = ["orientation_x", "orientation_y", "orientation_covariance", 
                         "angular_velocity_x", "angular_velocity_y", "angular_velocity_covariance",
                         "linear_acceleration_x", "linear_acceleration_y", "linear_acceleration_covariance"]
        '''

        # Loop through each message
        for topic, msg, t in bag.read_messages(topics = [topic]):
            row = {}

            # The following subtopics will be handled differently
            for oldname, newname in subtopic_dict.items():
                if (newname == 'ros_header_time'):
                    value = str(msg.header.stamp.secs) + str(msg.header.stamp.nsecs)

                elif (newname == 'ros_header_seconds'):
                    value = msg.header.stamp.secs

                elif (newname == 'ros_header_nanoseconds'):
                    value = msg.header.stamp.nsecs

                elif (newname == 'written_to_bag_time'):
                    value = str(t)
                    
                    '''
                    elif (subtopic == 'header'):
                        value = ""
                    elif (subtopic == 'seq'):
                        value = msg.header.seq
                    elif (subtopic == 'stamp'):
                        value = ""
                    elif (subtopic == 'frame_id'):
                        value = msg.header.frame_id
                    '''

                # The ousterO1/imu topic is handled uniquely - split the objects into separate x and y columns
                elif (topic == "/ousterO1/imu"):
                    # Handle subtopics ending in _x or _y in a certain way
                    if ("_x" in oldname or "_y" in oldname):
                        # Get the subtopic by itself (orientation, angular_velocity, or linear_acceleration)
                        subtopic_shortened = oldname[:-2]

                        # Get whether you are dealing with the _x or _y value
                        x_or_y = oldname[-1:]

                        # Based on the above, get the specfic attribute
                        value = getattr(getattr(msg, subtopic_shortened), x_or_y)
                    
                    # Otherwise, treat it the same as any other subtopic
                    else:
                        value = getattr(msg, oldname, None)
                
                else:
                    value = getattr(msg, oldname, None)
                    # print(value)
                    '''
                    if ("PVT" in topic):
                        if (newname == "longitude" or newname == "latitude"):
                            value = "None"
                    '''

                # From each key, you'll get a corresponding value (as seen above). Add this as a new entry to the row dictionary.
                row[newname] = value

            data.append(row)   # Add this new row to the data array

        # Make sure there was no mistake of no data being found
        if (len(data) > 0):
            df = pl.DataFrame(data)   # Create a polars data frame out of this data

            # For debugging:
            # Display the data frame using the helper function above
            # display_df(topic, df, True, False)
            # print(df.columns)
            
            # Only do the following if the table is in the database
            if table_name != "":
                df = update_df(df, table_name, mapping_dict, db_col_lst, bag_file_db_id, to_db, db)

            # Display the data frame using the helper function above
            debug_ouster_imu_flag = False
            # display_df(topic, df, False, debug_ouster_imu_flag)

            '''
            pd_df = df.to_pandas()

            csv_buffer = StringIO()
            pd_df.to_csv(csv_buffer, index = False, header = True, sep = ",", na_rep = "null")
            # csv_buffer = csv_buffer.replace("nan", "null")

            csv_buffer.seek(0)           # Rewind the buffer to the beginning for reading
            print(csv_buffer.read())   # For simple debugging, print the CSV string to ensure it's not empty'
            '''

        # If there was an error, print an error statement and create a blank data frame
        else:
            print("\t - Error creating dataframe.")
            df = pl.DataFrame()

    # Return the following:
    return df, table_name, db_col_lst