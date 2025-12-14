'''
Python 3.10.1 and Python 3.12.3

Written by Sadie Duncan at IVSG between Summer 2024 - Spring 2025
Supervised by Professor Sean Brennan

Purpose:
    The purpose of this script is to create a data frame from a CSV file.

Usage:
    Called from the parse_and_insert_v2.py script.

Method(s): csv_to_df(csv_file, bag_file_name, bag_file_id, to_db, db)
    Create a data frame given a CSV file.
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
import warnings
import pdb

# import psycopg2
import rosbag
import pandas as pd
import polars as pl
import numpy as np

from get_table_info import get_table_info
from update_df import update_df

def csv_to_df(csv_file, bag_file_db_id, to_db, db):
    # Use the Pandas library to read the CSV files, using commas to separate each value
    df_pandas = pd.read_csv(csv_file, sep = ",")
    df_pandas = df_pandas.dropna(how = "all")   # Drop rows where all elements are NaN

    # Transform into a polars data frame
    df = pl.DataFrame(df_pandas)

    # The table and topic name do not match - use the following to align the naming
    table_name = csv_file.split("/")[-1]
    table_name = table_name.replace("_slash_", "")   # Get rid the of "_slash_" in the naming
    table_name = table_name[:-4]                     # Get rid of the ".csv" part
    table_name = table_name.lower()                  # Make sure the name is all lowercase

    # Handle the ousterO1/imu topic specifically
    if ("ouster" in table_name and "imu" in table_name):
        table_name = "ousterO1_imu"

    # Handle the parse_encoder and parse_trigger topics
    if ("parse" in table_name):
        table_name = table_name.replace("parse", "")   # Get rid of the "parse" in the name (if there)
    
    table_name, mapping_dict, db_col_lst = get_table_info(table_name)   # Get information about the corresponding table

    # Display the first 3 rows of the data frame
    print(f"\nTotal size of '{table_name}' data frame: {df.shape}")
    print(f"Displaying the first 3 rows of '{table_name}' data frame: ")
    print(df.head(3))
    print()

    # Return the following
    return df, table_name, db_col_lst