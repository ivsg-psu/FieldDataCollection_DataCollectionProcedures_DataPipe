'''
Python 3.10.1 and Python 3.12.3

Written by Sadie Duncan at IVSG between Summer 2024 - Spring 2025
Supervised by Professor Sean Brennan

Purpose:
    The purpose of this script is provide a helper function
    that will transform dataframes into CSV files.

Usage:
    Use with the parse_and_insert_v2.py and use_database.py scripts.

Method(s): write_csv(folder, topic, df)
    Write a CSV file for a given topic from a corresponding data frame.
'''

from io import StringIO 
from pathlib import Path
import os, sys, csv, string

import numpy as np
import pandas as pd
import polars as pl
import pdb

def write_csv(folder, topic, df):
    '''
    # Determine the file name, skip if it is sick_lms or velodyne_points
    if topic == "/sick_lms500/scan" or topic == "/velodyne_points" or topic == "/velodyne_packets":
        filename = "pass"    
    else:
        filename = f"{folder}/{topic.replace('/', '_slash_')}.csv"   # Determining the file name
    
    if not os.path.exists(filename):     # Make sure the same file hasn"t been written already
        print(f"\nWriting a csv file for '{topic}'")
        if filename != "pass":
            if df.is_empty():            # If the data frame is empty, there must be an error
                print(f"\tThe {filename} data frame is empty. CSV file was not written.")
            else:
                pd_df = df.to_pandas()   # Convert the data frame to Pandas to be easier to write
                pd_df.to_csv(filename, index = False, header = True)   # Write the CSV file
                print(f"\t'{filename}' has been successfully written with {df.shape[0]} rows and {df.shape[1]} columns.")
    '''
    # Determine the file name
    filename = f"{folder}/{topic.replace('/', '_slash_')}.csv"
    
    if not os.path.exists(filename):     # Make sure the same file hasn"t been written already
        print(f"\nWriting a CSV file for '{topic}':")
        if df.is_empty():            # If the data frame is empty, there must be an error
            print(f"\t - The {filename} data frame is empty. CSV file was not written.")
        
        else:
            pd_df = df.to_pandas()   # Convert the data frame to Pandas to be easier to write
            pd_df.to_csv(filename, index = False, header = True)   # Write the CSV file
            print(f"\t + '{filename}' has been successfully written with {df.shape[0]} rows and {df.shape[1]} columns.")