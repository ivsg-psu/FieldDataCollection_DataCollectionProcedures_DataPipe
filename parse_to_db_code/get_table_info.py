'''
Python 3.10.1 and Python 3.12.3

Written by Sadie Duncan at IVSG between Summer 2024 - Spring 2025
Supervised by Professor Sean Brennan

Purpose:
    This script keeps track of the differences between the ROS bag topics and its data types and the SQL database table columns
    and their data types. Currently, only contains information for the encoder, GPS SparkFun sensors, the 3D LiDAR sensors, and trigger.

Usage:
    Use with the parse_and_insert.py script.

Method(s):
    - get_topics(topic)
        Takes in a table name and will return the proper table_name, a mapping dictionary of the ROS bag topics and
        corresponding database column names and data types, and a list of the columns for the database table.
    - debug()
        Helps test whether the remapping of the keys and values in the dictionaries are properly updated.

For adding in a future table:
    1. Update the SQL script
        a. New CREATE TABLE
        b. New ADD FOREIGN KEY
    2. Create a new "if" statement to check whether the table_name matches that of the newly added table
    3. Create a dictionary (mapping_dict)
        a. Keys are the topics you want from the ROS bag / the older CSV files
        b. Values are a list of the corresponding name in the database table and proper datatype. To ensure data can be written to
           the database, we will cast each value to be the same type as is in the database.
        c. Postgres - Polars Transformations:
                char/varchar/text = pl.Utf8
                int = pl.Int32
                bigint = pl.Int64
                real = pl.Float32
                float = pl.Float64
    4. Create a list (db_col_lst) that includes the columns in the new database table 
'''
import polars as pl

def get_table_info(table_name):
    # Declare and initialize the dictionary and list to be empty
    mapping_dict = {}
    db_col_lst = []

    # Table: encoder
    if (table_name == 'encoder'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'mode': ['encoder_mode', pl.Utf8],
                        'C1': ['c1', pl.Int64],
                        'C2': ['c2', pl.Int64],
                        'C3': ['c3', pl.Int64],
                        'C4': ['c4', pl.Int64],
                        'P1': ['p1', pl.Int64],
                        'E1': ['e1', pl.Int64],
                        'err_wrong_element_length': ['err_wrong_element_length', pl.Int32],
                        'err_bad_element_structure': ['err_bad_element_structure', pl.Int32],
                        'err_failed_time': ['err_failed_time', pl.Int32],
                        'err_bad_uppercase_character': ['err_bad_uppercase_character', pl.Int32],
                        'err_bad_lowercase_character': ['err_bad_lowercase_character', pl.Int32],
                        'err_bad_character': ['err_bad_character', pl.Int32]
        }
        
        db_col_lst = ['bag_file_db_id', 'encoder_mode',
                      'c1', 'c2', 'c3', 'c4', 'p1', 'e1',
                      'err_wrong_element_length', 'err_bad_element_structure',
                      'err_failed_time', 'err_bad_uppercase_character',
                      'err_bad_lowercase_character', 'err_bad_character',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]
        
    # Table: gps_sparkfun_gga (left, right, or front)
    elif (table_name == 'gps_sparkfun_rearleft_gga' or table_name == 'gps_sparkfun_rearright_gga' or table_name == 'gps_sparkfun_front_gga'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'GPSSecs': ['gps_secs', pl.Int64],
                        'GPSMicroSecs': ['gps_microsecs', pl.Int64],
                        'Latitude': ['latitude', pl.Float32],
                        'Longitude': ['longitude', pl.Float32],
                        'Altitude': ['altitude', pl.Float32],
                        'GeoSep': ['geosep', pl.Float32],
                        'NavMode': ['nav_mode', pl.Int32],
                        'NumOfSats': ['num_of_sats', pl.Int32],
                        'HDOP': ['hdop', pl.Float64],
                        'AgeOfDiff': ['age_of_diff', pl.Float64],
                        'LockStatus': ['lock_status', pl.Int32],
                        'BaseStationID': ['base_station_messages_id', pl.Utf8]
        }
        
        db_col_lst = ['bag_file_db_id', 'base_station_messages_id',
                      'gps_secs', 'gps_microsecs', 'gps_time',
                      'latitude', 'longitude', 'altitude',
                      'geosep', 'nav_mode', 'num_of_sats',
                      'hdop', 'age_of_diff', 'lock_status',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'              
        ]

    # Table: gps_sparkfun_pvt (left, right, or front)
    elif (table_name == 'gps_sparkfun_rearleft_pvt' or table_name == 'gps_sparkfun_rearright_pvt' or table_name == 'gps_sparkfun_front_pvt'):
        '''
        rosbagTimestamp
        iTOW
        year
        month
        day
        hour
        min
        sec
        valid
        tAcc
        nano
        fixType
        flags
        flags2
        numSV	
        longitude
        latitude
        height
        hMSL
        hAcc
        vAcc
        velN
        velE
        velD
        gSpeed
        heading
        sAcc
        headAcc
        pDOP
        reserved1
        headVeh
        magDec
        magAcc
        '''    
        '''    
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Int64],
                        'iTOW' : ['itow', pl.Int64],
                        'year' : ['gps_year', pl.Int64],
                        'month' : ['gps_month', pl.Int64],
                        'day' : ['gps_day', pl.Int64],
                        'hour' : ['gps_hour', pl.Int64],
                        'min' : ['gps_min', pl.Int64],
                        'sec' : ['gps_sec', pl.Int64],
                        'valid' : ['valid', pl.Int32],
                        'tAcc' : ['t_acc', pl.Float32],
                        'nano' : ['nano', pl.Int64],
                        'fixType' : ['fix_type', pl.Int32],
                        'flags' : ['flags', pl.Int64],
                        'flags2' : ['flags2', pl.Int64],
                        'numSV' : ['num_sv', pl.Int32],	
                        'longitude' : ['longitude', pl.Float32],
                        'latitude' : ['latitude', pl.Float32],
                        'height' : ['altitude', pl.Float32],
                        'hMSL' : ['h_msl', pl.Int64],
                        'hAcc' : ['h_acc', pl.Float32],
                        'vAcc' : ['v_acc', pl.Float32],
                        'velN' : ['vel_n', pl.Float32],
                        'velE' : ['vel_e', pl.Float32],
                        'velD' : ['vel_d', pl.Float32],
                        'gSpeed' : ['g_speed', pl.Float32],
                        'heading' : ['heading', pl.Float32],
                        'sAcc' : ['s_acc', pl.Float32],
                        'headAcc' : ['head_acc', pl.Float32],
                        'pDOP' : ['p_dop', pl.Int32],
                        'headVeh' : ['head_veh', pl.Int32],
                        'magDec' : ['mag_dec', pl.Int32],
                        'magAcc' : ['mag_acc', pl.Int32],
        }
        
        db_col_lst = ['bag_file_db_id', 'itow',
                      'gps_time', 'gps_year', 'gps_month', 'gps_day', 'gps_hour', 'gps_min', 'gps_secs',
                      'valid', 't_acc', 'nano', 'fix_type', 'flags', 'flags2', 'num_sv',
                      'longitude', 'latitude', 'altitude',
                      'h_msl', 'h_acc', 'v_acc', 'vel_n', 'vel_e', 'vel_d',
                      'g_speed', 'heading', 's_acc', 'head_acc', 'p_dop',
                      'head_veh', 'mag_dec', 'mag_acc', 
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]
        '''

        mapping_dict = {'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'iTOW' : ['itow', pl.Int64],
                        'year' : ['gps_year', pl.Int64],
                        'month' : ['gps_month', pl.Int64],
                        'day' : ['gps_day', pl.Int64],
                        'hour' : ['gps_hour', pl.Int64],
                        'min' : ['gps_min', pl.Int64],
                        'sec' : ['gps_secs', pl.Int64],
                        'valid' : ['valid', pl.Int32],
                        'tAcc' : ['t_acc', pl.Float32],
                        'nano' : ['nano', pl.Int64],
                        'fixType' : ['fix_type', pl.Int32],
                        'flags' : ['flags', pl.Int64],
                        'flags2' : ['flags2', pl.Int64],
                        'numSV' : ['num_sv', pl.Int32],	
                        'longitude' : ['longitude', pl.Utf8],
                        'latitude' : ['latitude', pl.Utf8],
                        'height' : ['altitude', pl.Float32],
                        'hMSL' : ['h_msl', pl.Int64],
                        'hAcc' : ['h_acc', pl.Float32],
                        'vAcc' : ['v_acc', pl.Float32],
                        'velN' : ['vel_n', pl.Float32],
                        'velE' : ['vel_e', pl.Float32],
                        'velD' : ['vel_d', pl.Float32],
                        'gSpeed' : ['g_speed', pl.Float32],
                        'heading' : ['heading', pl.Float32],
                        'sAcc' : ['s_acc', pl.Float32],
                        'headAcc' : ['head_acc', pl.Float32],
                        'pDOP' : ['p_dop', pl.Int32],
                        'headVeh' : ['head_veh', pl.Int32],
                        'magDec' : ['mag_dec', pl.Int32],
                        'magAcc' : ['mag_acc', pl.Int32],
        }
        
        db_col_lst = ['bag_file_db_id', 'itow',
                      'gps_year', 'gps_month', 'gps_day', 'gps_hour', 'gps_min', 'gps_secs',
                      'valid', 't_acc', 'nano', 'fix_type', 'flags', 'flags2', 'num_sv',
                      'longitude', 'latitude', 'altitude',
                      'h_msl', 'h_acc', 'v_acc', 'vel_n', 'vel_e', 'vel_d',
                      'g_speed', 'heading', 's_acc', 'head_acc', 'p_dop',
                      'head_veh', 'mag_dec', 'mag_acc', 
                      'written_to_bag_time'
        ]

    # Table: gps_sparkfun_gst (left, right, or front)
    elif (table_name == 'gps_sparkfun_rearleft_gst' or table_name == 'gps_sparkfun_rearright_gst' or table_name == 'gps_sparkfun_front_gst'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'StdMajor': ['stdmajor', pl.Float64],
                        'StdMinor': ['stdminor', pl.Float64],
                        'StdOri': ['stdori', pl.Float64],
                        'StdLat': ['stdlat', pl.Float64],
                        'StdLon': ['stdlon', pl.Float64],
                        'StdAlt': ['stdalt', pl.Float64]
        }

        db_col_lst = ['bag_file_db_id',
                      'stdmajor', 'stdminor', 'stdori',
                      'stdlat', 'stdlon', 'stdalt',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]

    # Table: gps_sparkfun_vtg (left, right, or front)
    elif (table_name == 'gps_sparkfun_rearleft_vtg' or table_name == 'gps_sparkfun_rearright_vtg' or table_name == 'gps_sparkfun_front_vtg'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'TrueTrack': ['true_track', pl.Float32],
                        'MagTrack': ['mag_track', pl.Float32],
                        'SpdOverGrndKnots': ['spdovergrndknots', pl.Float32],
                        'SpdOverGrndKmph': ['spdovergrndkmph', pl.Float32]
        }

        db_col_lst = ['bag_file_db_id', 'true_track', 'mag_track',
                      'spdovergrndknots', 'spdovergrndkmph',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]

    # Table: sick_lms_5xx
    elif (table_name == 'sick_lms_5xx'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'angle_min' : ['angle_min', pl.Float32],
                        'angle_max' : ['angle_max', pl.Float32],
                        'angle_increment' : ['angle_increment', pl.Float32],
                        'time_increment' : ['time_increment', pl.Float32],
                        'scan_time' : ['scan_time', pl.Float32],
                        'range_min' : ['range_min', pl.Float32],
                        'range_max' : ['range_max', pl.Float32],
                        'ranges' : ['ranges', pl.Utf8],
                        'intensities' : ['intensities', pl.Utf8]
        }

        db_col_lst = ['bag_file_db_id', 'scan_time', 'time_increment',
                      'angle_min', 'angle_max', 'angle_increment',
                      'range_min', 'range_max', 'ranges', 'intensities', 
                      'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]

    # Table: oustero1_imu
    elif (table_name == 'oustero1_imu'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'orientation_x' : ['orientation_x', pl.Float64],
                        'orientation_y' : ['orientation_y', pl.Float64],
                        # 'orientation_covariance' : ['orientation_covariance', pl.List(pl.Float64)],
                        'angular_velocity_x' : ['angular_velocity_x', pl.Float64],
                        'angular_velocity_y' : ['angular_velocity_y', pl.Float64],
                        # 'angular_velocity_covariance' : ['angular_velocity_covariance', pl.List(pl.Float64)],
                        'linear_acceleration_x' : ['linear_acceleration_x', pl.Float64],
                        'linear_acceleration_y' : ['linear_acceleration_y', pl.Float64]
                        # 'linear_acceleration_covariance' : ['linear_acceleration_covariance', pl.List(pl.Float64)]
        }

        '''
        db_col_lst = ['bag_file_db_id', 'orientation_x', 'orientation_y', 'orientation_covariance',
                      'angular_velocity_x', 'angular_velocity_y', 'angular_velocity_covariance',
                      'linear_acceleration_x', 'linear_acceleration_y', 'linear_acceleration_covariance',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]
        '''

        db_col_lst = ['bag_file_db_id',
                      'orientation_x', 'orientation_y',
                      'angular_velocity_x', 'angular_velocity_y',
                      'linear_acceleration_x', 'linear_acceleration_y',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]
        
    # Table: velodyne_lidar
    elif (table_name == 'velodyne_lidar'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'velodyne_hash': ['velodyne_hash', pl.Utf8],
                        'velodyne_hash_root_folder_name': ['velodyne_hash_root_folder_name', pl.Utf8],
                        'velodyne_file_size' : ['velodyne_file_size', pl.Int64],
                        'velodyne_sensor_time' : ['velodyne_sensor_time', pl.Int64],
                        'velodyne_host_time' : ['velodyne_host_time', pl.Int64],
                        'velodyne_average_header_time' : ['velodyne_average_header_time', pl.Int64],
                        'velodyne_bag_time' : ['velodyne_bag_time', pl.Int64]
        }

        db_col_lst = ['bag_file_db_id', 
                      'velodyne_hash', 'velodyne_hash_root_folder_name', 'velodyne_file_size', 
                      'velodyne_sensor_time', 'velodyne_host_time',
                      'velodyne_average_header_time', 'velodyne_bag_time',
                      'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]

    # Table: ouster_lidar
    elif (table_name == 'ouster_lidar'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'ouster_hash': ['ouster_hash', pl.Utf8],
                        'ouster_range_image_hash': ['ouster_range_image_hash', pl.Utf8],
                        'ouster_signal_image_hash': ['ouster_signal_image_hash', pl.Utf8],
                        'ouster_reflective_image_hash': ['ouster_reflective_image_hash', pl.Utf8],
                        'ouster_nearir_image_hash': ['ouster_nearir_image_hash', pl.Utf8],
                        'ouster_hash_root_folder_name': ['ouster_hash_root_folder_name', pl.Utf8],
                        'ouster_file_size' : ['ouster_file_size', pl.Int64],
                        'ouster_sensor_time' : ['ouster_sensor_time', pl.Int64],
                        'ouster_host_time' : ['ouster_host_time', pl.Int64],
                        'ouster_average_header_time' : ['ouster_average_header_time', pl.Int64],
                        'ouster_bag_time' : ['ouster_bag_time', pl.Int64]
        }

        db_col_lst = ['bag_file_db_id', 
                      'ouster_hash', 'ouster_range_image_hash',
                      'ouster_signal_image_hash', 'ouster_reflective_image_hash',
                      'ouster_nearir_image_hash', 'ouster_hash_root_folder_name',
                      'ouster_sensor_time', 'ouster_host_time',
                      'ouster_average_header_time', 'ouster_bag_time',
                      'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]
        
    # Table: trigger
    elif (table_name == 'trigger'):
        mapping_dict = {'rosbagTimestamp' : ['ros_header_time', pl.Utf8],
                        'ros_header_seconds' : ['ros_header_seconds', pl.Utf8],
                        'ros_header_nanoseconds' : ['ros_header_nanoseconds', pl.Utf8],
                        'written_to_bag_time' : ['written_to_bag_time', pl.Utf8],
                        'mode': ['trigger_mode', pl.Utf8],
                        'mode_counts': ['trigger_mode_counts', pl.Int32],
                        'adjone': ['adjone', pl.Int32],
                        'adjtwo': ['adjtwo', pl.Int32],
                        'adjthree': ['adjthree', pl.Int32],
                        'err_failed_mode_count': ['err_failed_mode_count', pl.Int32],
                        'err_failed_XI_format': ['err_failed_xi_format', pl.Int32],
                        'err_failed_checkInformation': ['err_failed_check_information', pl.Int32],
                        'err_trigger_unknown_error_occured': ['err_trigger_unknown_error_occured', pl.Int32],
                        'err_bad_uppercase_character': ['err_bad_uppercase_character', pl.Int32],
                        'err_bad_lowercase_character': ['err_bad_lowercase_character', pl.Int32],
                        'err_bad_three_adj_element': ['err_bad_three_adj_element', pl.Int32],
                        'err_bad_first_element': ['err_bad_first_element', pl.Int32],
                        'err_bad_character': ['err_bad_character', pl.Int32],
                        'err_wrong_element_length': ['err_wrong_element_length', pl.Int32]
        }

        db_col_lst = ['bag_file_db_id', 'trigger_mode', 'trigger_mode_counts',
                      'adjone', 'adjtwo', 'adjthree',
                      'err_failed_mode_count', 'err_failed_xi_format', 'err_failed_check_information',
                      'err_trigger_unknown_error_occured', 'err_bad_uppercase_character',
                      'err_bad_lowercase_character', 'err_bad_three_adj_element',
                      'err_bad_first_element', 'err_bad_character', 'err_wrong_element_length',
                      'written_to_bag_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'ros_header_time'
        ]
    
    else:
        table_name = ""
        mapping_dict = {}
        db_col_lst = []

    return table_name, mapping_dict, db_col_lst

def debug():
    # Choose a specific topic and call the function above
    table_to_test = "oustero1_imu"
    table_name, mapping_dict, db_col_lst = get_table_info(table_to_test)

    # Determine what you want to debug
    check_outputs = 1
    check_remapping = 0

    # Check the outputs of the get_table_info function
    if (check_outputs == 1):
        print(f'table_name: {table_name}')
        print(f'mapping_dict: {mapping_dict}')
        print(f'db_col_lst: {db_col_lst}')

    # Check remapping the dictionary items and values
    if (check_remapping == 1):
        # Test renaming and recasting items and values in the dictionary
        name_map = {old_name : new_name[0] for old_name, new_name in mapping_dict.items()}
        type_map = {new_name : new_type for new_name, new_type in mapping_dict.values()}

        # Check results
        print('Testing Comparing Names:')
        for name1, name2 in name_map.items():
            print(f'\t{name1}: {name2}')

        print('-' * 150)

        print('\nTesting Comparing Data Types:')
        for name, type in type_map.items():
            print(f'\t{name}: {type}')

# debug()