r'''
Testing Path: "C:\Users\USER\Desktop\parse_test"
'''

from pathlib import Path
import os
import sys
import argparse
import time

import rosbag
import pandas as pd
import polars as pl

import use_database
import parse_pose
import parse_utilities
from parse_camera import parseCamera
from parse_velodyne import parse_velodyne
from write_csv import write_csv

flags = {
    "write_time_log" : 0,
    "read_bag_files" : 1,
    "pose"           : 1,
    "camera"         : 1,
    "velodyne"       : 1,
    "ouster"         : 0,
    "display_df"     : 0,
    "to_csv"         : 0,
    "to_db"          : 1
}

db_login_info = {
    "db_username" : "postgres",
    "db_password" : "pass",
    "db_host"   : "127.0.0.1",
    "db_port"     : "5432",
    "db_name"     : ""
}

db_tables = ['/velodyne_packets', '/parseTrigger', 'parseEncoder',
             '/GPS_SparkFun_RearLeft_GGA', '/GPS_SparkFun_RearLeft_PVT', '/GPS_SparkFun_RearLeft_GST', '/GPS_SparkFun_RearLeft_VTG',
             '/GPS_SparkFun_RearRight_GGA', '/GPS_SparkFun_RearRight_PVT', '/GPS_SparkFun_RearRight_GST', '/GPS_SparkFun_RearRight_VTG',
             '/GPS_SparkFun_Front_GGA', '/GPS_SparkFun_Front_PVT', '/GPS_SparkFun_Front_VTG', '/ousterO1/imu']

def parse_arugments():
    # Describe the argument parser
    arg_parser_description = "Read bag or CSV files from the source directory and save parsed files to a destination directory."
    arg_parser = argparse.ArgumentParser(description = arg_parser_description)

    # Determine the various valid arguments
    arg_parser.add_argument("-s", "--sourcePath", required = True, help = "Path to the source directory.", type = str)
    arg_parser.add_argument("-d", "--destinationPath", required = True, help = "Path to the destination directory.", type = str)
    arg_parser.add_argument("-f", "--fileName", required = False, help = "Specific file to parse.")
    arg_parser.add_argument("-a", "--allFiles", required = False, action = "store_true", help = "Parse all files in the source path and its subfolders.")
    
    # Access the input arguments
    input_args = arg_parser.parse_args()
    
    # Get the source and destination path
    path_to_source = input_args.sourcePath.replace("\\", "/")
    path_to_dest = input_args.destinationPath.replace("\\", "/")
    
    # Check if the given paths actually exist
    if not os.path.exists(path_to_source) or not os.path.exists(path_to_dest):
        print(f"Error - At least one of the given paths does not exist.\n")
        sys.exit(1)
    
    files_to_parse = []
    
    arg_count = len(sys.argv)
    if (arg_count > 7):
        print(f"""Error - Too many arguments given ({arg_count}) \n   There hould be 5: script -s sourcePath -d destinationPath, \n     or 6: script -s sourcePath -d destinationPath -a, \n     or 7: script -s sourcePath -d destinationPath -f fileName""")
        sys.exit(1)
        
    elif (input_args.fileName):
        path_to_file = os.path.join(path_to_source, input_args.fileName) 
        path_to_file = os.path.normpath(path_to_file)
        
        if os.path.exists(path_to_file):
            files_to_parse = [input_args.fileName]
        else:
            print(f"Error - The given file does not exist: '{path_to_file}'.\n")
            sys.exit(1)
        
    elif (input_args.allFiles):
        root_path = Path(path_to_source)
        files_to_parse = [str(p.relative_to(root_path)) for p in root_path.rglob("*") if p.suffix in [".bag", ".csv"]]
        
    elif (arg_count == 5):
        files_to_parse = [f for f in os.listdir(path_to_source) if f.endswith(".bag") or f.endswith(".csv")]
    
    else:
        print(f"Bad argument(s): {sys.argv}")
        sys.exit(1)
        
    if (flags["read_bag_files"]):
        files_to_parse = [file for file in files_to_parse if (
            ".active" not in file and 
            "OusterO1_Images" not in file and 
            "velodynePoints" not in file)]
        
        if ((flags["pose"] + flags["velodyne"]) == 0):
            files_to_parse = [file for file in files_to_parse if (
                "cameras" in file or 
                "OusterO1" in file)]
            
        if (flags["camera"] == 0):
            files_to_parse = [file for file in files_to_parse if "cameras" not in file]
            
        if (flags["ouster"] == 0):
            files_to_parse = [file for file in files_to_parse if "OusterO1_Raw" not in file]

    else:
        files_to_parse = [file for file in files_to_parse if ".csv" in file]
        
    print(f"\nPath to Source: {path_to_source}")
    print(f"Path to Destination: {path_to_dest}\n")
    parse_utilities.print_file_list(files_to_parse)
        
    return path_to_source, path_to_dest, files_to_parse

'''
Return information about topics and subtopics in the input bag file. Can also use this function to check
the subtopics for a new bag file topic. Also return an updated destination path for the bag contents.
'''
def get_bag_info(bag_file, path_to_source, path_to_dest):
    # Note - An example for the path_to_source and path_to_dest: /home/USER/Desktop

    # Access the actual bag file path (ex. /home/USER/Desktop/mapping_van_2024-10-21-11-06-56_0.bag)
    path_to_bag = os.path.join(path_to_source, bag_file) 
    path_to_bag = os.path.normpath(path_to_bag)
    
    # Create an instance of the rosbag
    bag = rosbag.Bag(path_to_bag)
    
    # Cut off the '.bag' to determine the actual bag/folder name (ex. mapping_van_2024-10-21-11-06-56_0)
    bag_name = bag_file[:-4]
    
    # Determine the path to the destination folder (ex. /home/USER/Desktop/mapping_van_2024-10-21-11-06-56_0)
    path_to_new_bag_dir = os.path.join(path_to_dest, bag_name) 
    path_to_new_bag_dir = os.path.normpath(path_to_new_bag_dir)


    # Keep track of the topics and subtopics in a bag
    topic_subtopic_dict = {}
    topic_lst = []

    # Loop through the bag messages
    for topic, msg, t in bag.read_messages():
        subtopics = msg.__slots__

        # Make sure the topics and subtopics are unique
        if topic not in topic_lst and subtopics not in topic_subtopic_dict.items():
            # Don't bother with data that won't go to the database or isn't related to the cameras or OusterO1_Raw
            if (("cameras" in bag_name) or ("OusterO1_Raw" in bag_name) or (topic in db_tables)):
                # Update the list and dictionary
                topic_lst.append(topic)
                topic_subtopic_dict.update({topic : subtopics})

    # Print information about the topics
    print(f"For '{bag_file}', these {len(topic_lst)} topics will be parsed: {topic_lst}")
    print("-" * 100)
    
    # Return relevant information
    return bag, path_to_bag, bag_name, path_to_new_bag_dir, topic_subtopic_dict, topic_lst

def main():
    start_time = time.time()
    
    path_to_source, path_to_dest, files_to_parse = parse_arugments()
    
    try:
        if (flags["to_db"]):
            db_name = input("Please enter the name of the database you'd like to connect to: ")
            db_login_info["db_name"] = db_name
            
        # Design the Postgres URL: postgresql://<username>:<password>@<host>:<port>/<database name>
        db_login_info_lst = list(db_login_info.values())
        db_url = f"postgresql://{db_login_info_lst[0]}:{db_login_info_lst[1]}@{db_login_info_lst[2]}:{db_login_info_lst[3]}/{db_login_info_lst[4]}"
        
        # Connect to the database
        db = use_database.Database(flags["to_db"], db_url)
        print("─" * 125)
        
    except:
        print("Error connecting to the database. Please check database connection parameters.")
        sys.exit()
        
    # Determine the names of the different folders
    site_folder_name = os.path.basename(path_to_source)
    site_folder_name_nonspace = site_folder_name.replace(" ", "_")
    hash_name_Cameras = f"hashCameras_{site_folder_name_nonspace}"
    hash_name_Velodyne = f"hashVelodyne_{site_folder_name_nonspace}"
    hash_name_OusterO1 = f"hashOusterO1_{site_folder_name_nonspace}"

    # For debugging the above:
    # print(f"""(Debugging) Folder Names:
    #     site_folder_name: {site_folder_name}
    #     site_folder_name_nonspace: {site_folder_name_nonspace}
    #     hash_name_Cameras: {hash_name_Cameras}
    #     hash_name_Velodyne: {hash_name_Velodyne}
    #     hash_name_OusterO1: {hash_name_OusterO1}""")
    
    file_count = 0
    # files_to_parse = [files_to_parse[0]]
    for file in files_to_parse:
        file_start_time = time.time()
        file_count += 1
        
        dfs_created = 0
        df = pl.DataFrame()
        
        if (flags["read_bag_files"] == 0):
            print("Handling CSV files...\n")
        
        else:        
            bag, path_to_bag, bag_name, path_to_new_bag_dir, topic_subtopic_dict, topic_lst = get_bag_info(file, path_to_source, path_to_dest)
            
            # For debugging the above:
            # print(f"""(Debugging) Bag Info:
            #     path_to_bag: {path_to_bag}
            #     bag_name: {bag_name}
            #     path_to_new_bag_dir: {path_to_new_bag_dir}
            #     topic_subtopic_dict: {topic_subtopic_dict}
            #     topic_lst: {topic_lst}""")
            
            # Make a new folder - unless you are just doing pose data and not writing to CSV files
            if (flags["camera"] or flags["velodyne"] or flags["ouster"] or (flags["pose"] and flags["to_csv"])): 
                parse_utilities.make_folder(path_to_new_bag_dir, bag_name)
            
            if (flags["to_db"] == 1):
                bag_file_db_id = db.get_bag_id_from_name(bag_name)
                
                if (bag_file_db_id == None):
                    bag_file_db_id = db.insert_new_bag(bag_name)
                
            else:
                bag_file_db_id = 1  
                
            # Handle Ouster data
            if ("OusterO1_Raw" in file):
                if (flags["ouster"]):
                    print("Skipping Ouster data now.\n")
                    
                    # To-do: Fix the following function
                    print(f"Now parsing: OusterO1_Raw")
                    # df = parse_ouster(path_to_source, path_to_bag, path_to_dest, hash_name_OusterO1, file, bag_file_db_id, db, flags["to_db"])
                    
                    if (df.is_empty() == False):
                        bag_df_count += 1

                    print("\t + OusterO1_Raw data has been parsed.")

                else:
                    print("\t - OusterO1_Raw data will not be parsed.\n")
            else:
                for topic, subtopics in topic_subtopic_dict.items():
                    topic_start_time = time.time()
                    
                    if (flags["display_df"]):
                        print(f"Now working on: '{topic}'...\n")
                        
                    # Handle camera data
                    if ("cameras" in file):
                        if (flags["camera"]):
                            # Ceeate an instance of the parseCamera class
                            pc = parseCamera(path_to_source, path_to_bag, path_to_dest, bag, hash_name_Cameras, bag_file_db_id, flags["to_db"], db)
                            
                            output_file_name = f"{path_to_dest}/{bag_name}/{topic.replace('/', '_slash_')}.txt"    
                            df, table_name, db_col_lst = pc.parseCamera(topic, output_file_name)   # Create a data frame
                                
                        else:
                            print(f"\t - Camera topic '{topic}' will not be parsed.")
                            
                    # Handle Velodyne data
                    elif (topic == "/velodyne_packets"): 
                        if (flags["velodyne"]):
                            df, table_name, db_col_lst = parse_velodyne(path_to_source, path_to_bag, path_to_dest, hash_name_Velodyne, topic, bag, bag_file_db_id, db, flags["to_db"])   # Create a data frame
                                
                        else:
                            print(f"\t - Camera topic '{topic}' will not be parsed.")
                        
                    # Handle pose data
                    elif (flags["pose"]):    
                        df, table_name, db_col_lst = parse_pose.parse_pose_topics(bag, topic, subtopics, bag_file_db_id, flags["to_db"], db)
                        
                        if ((df.is_empty() == False) and (flags["to_csv"])):
                            write_csv(path_to_dest, topic, df)
                    
                    else:
                        print("No flags set to parse any data types.")
                        
                    if (df.is_empty() == False):
                        dfs_created += 1
                        
                        if (flags["display_df"]):
                            print(f"Displaying the first 3 rows of '{topic}' in '{table_name}':")
                            print(df.head(3))
                            
                        if (flags["to_db"]):
                            if table_name != None:
                                db.df_to_db(table_name, df, db_col_lst)
                                
        # Display information about the number of bag file data frames created
        if ((dfs_created > 0)):
            print("-" * 125)
            print(f"Total data frames for file #{file_count}/{len(files_to_parse)} created: {dfs_created}\n")

        if (flags["to_db"]):
            db.check_and_commit(db_name)
                                            
        file_runtime = parse_utilities.display_runtime(file_start_time, "File", False)
    
    # Disconnect from the database (if connected)
    if (flags["to_db"]):
        db_size_bytes, db_size_mb = db.get_db_size(db_name)
        print(f"Final Database Size: {db_size_bytes} bytes ({db_size_mb} MB)")
        print("Final Table Entry Counts:")
        db_tables = db.get_tables(1)
        print()
        db.disconnect()
        
    total_runtime = parse_utilities.display_runtime(start_time, "Total", False)
    
if __name__ == "__main__":
    main()
