'''
Python 3.10.1 and Python 3.12.3

Written by Sadie Duncan at IVSG between Summer 2024 - Spring 2025
Supervised by Professor Sean Brennan

Purpose:
    The purpose of this script is provide a helper function
    that will update a dataframe so that it can be properly inserted
    into the database.

Usage:
    Use with the parse_and_insert_v2.py and use_database.py scripts.

Method(s): update_df(df, table_name, mapping_dict, db_col_lst, bag_file_db_id, to_db, db)
    Rename and recast columns to match database tables. Drop unnecessary columns and add
    new bag file id columns and timing columns. If a GGA sensor, add in a new column for
    base station messages. Finally, reorder the columns to match with the database table 
    order.
'''
import polars as pl

def update_df(df, table_name, mapping_dict, db_col_lst, bag_file_db_id, to_db, db):
    try:
        '''
        Start by renaming and recasting the columns name and data types. Also drop any columns that won't
        be inserted into the database.

        Since the values in the mapping_dict are a list, create a new dictionary made of the same key but 
        with the value being 1 of the items from the original value list
        '''
        # Rename the columns
        name_map = {old_name : new_name[0] for old_name, new_name in mapping_dict.items()}
        # df = df.rename(name_map)

        # Ensure that columns have the same data types
        type_map = {new_name : new_type for new_name, new_type in mapping_dict.values()}
        for name, type in type_map.items():
            if name in df.columns:
                df = df.with_columns([pl.col(name).cast(type)])
        
        # Drop any columns not in the name_map
        cols_to_keep = list(name_map.values())
        df = df.select(cols_to_keep)

        # Create a new column for the bag_file_db_id, which should be the same as bags are read one at a time
        bag_file_column = pl.Series('bag_file_db_id', [bag_file_db_id] * df.height, dtype =  pl.Int32)
        df = df.with_columns(bag_file_column)
        # print("\t\t + New column for bag_file_db_id added.")

        '''
        NOTE: gpstime and ros_header_time are both in nanoseconds
        Add a column for ros_header_seconds and ros_header_nanoseconds (calculated from ros_header_time)
            - ros_header_seconds = first 10 digits of ros_header_time
            - ros nanoseconds = last 9 digits of ros_header_time
            - leading 0's are dropped
        '''
        '''
        ros_header_seconds_col = (pl.col('ros_header_time').str.slice(0, 10).cast(pl.Int64)).alias('ros_header_seconds')
        ros_header_nanoseconds_col = (pl.col('ros_header_time').str.slice(10, 21).cast(pl.Int64)).alias('ros_header_nanoseconds')
        df = df.with_columns(ros_header_seconds_col)
        df = df.with_columns(ros_header_nanoseconds_col)
        '''

        if ("pvt" in table_name):
            df = df.with_columns(pl.col("written_to_bag_time").cast(pl.Int64))
        else:
            time_cols = ["ros_header_time", "ros_header_seconds", "ros_header_nanoseconds", "written_to_bag_time"]
            for time_col in time_cols:
                df = df.with_columns(pl.col(time_col).cast(pl.Int64))
        
        # df = df.with_columns(pl.col("ros_header_time").cast(pl.Int64))
        # df = df.with_columns(pl.col("written_to_bag_time").cast(pl.Int64))
        # # print("\t\t + New column for ros_header_seconds and ros_header_nanoseconds added.")

        '''
        if ('pvt' in table_name):
            df = df.with_columns(pl.lit(None).cast(pl.Float32).alias('longitude'))
            df = df.with_columns(pl.lit(None).cast(pl.Float32).alias('latitude'))
            # df = df.with_columns(pl.col('longitude').map(lambda x: None if x == '' else float(x), return_dtype = pl.Float32))
            # df = df.with_columns(pl.col('latitude').map(lambda x: None if x == '' else float(x), return_dtype = pl.Float32))
        '''

        # if ('gga' in table_name or 'pvt' in table_name):
        if ('gga' in table_name):
            '''
            Add a column for gpstime: gpstime = (gpssecs * 10^9) + (gpsmicrosecs * 10^3)
                - gpssecs in seconds     ->   multiply by 10^9 to converrt to nanoseconds
                - gpsnecs in microsecs   ->   multiply by 10^3 to convert to nanoseconds
            '''
            time_exp_nano = 10**(9)
            time_exp_micro = 10**(3)
            gpstime_column = (((pl.col('gps_secs') * time_exp_nano) + (pl.col('gps_microsecs') * time_exp_micro)).cast(pl.Int64).alias('gps_time'))
            df = df.with_columns(gpstime_column)
            # print("\t\t + New column for gpstime added.")

            # Debugging time variables
            '''
            time_lst = ['ros_header_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'gps_secs', 'gps_microsecs', 'gps_time']
            time_df = df.select(time_lst)
            print(f"Displaying the first 3 rows of time variables in this data frame: ")
            print(time_df.head(3))
            '''

        # GGA sensor has a column for base station - access the database for this to get the id of the base station
        if ('gga' in table_name):
            base_station_id_no_db = 0
            base_stations_no_db = []

            base_station_id_lst = []
            
            # Make a list out of all of the values in the 'BaseStationID' column
            base_station_column = df.select(pl.col('base_station_messages_id'))
            base_station_lst = base_station_column.to_series().str.strip_chars('"').to_list()

            # For each base station in this list, find the corresponding id in the database (will insert if not already there),
            # then add this to another list of all of the ids
            for base_station in base_station_lst:
                if (to_db == 1):
                    base_station_id = db.get_base_station_id(base_station)
                    base_station_id_lst.append(base_station_id)
                        
                else:
                    if base_station not in base_stations_no_db:
                        base_stations_no_db.append(base_station)
                        base_station_id_no_db += 1
                    base_station_id_lst.append(base_station_id_no_db)

            # Drop the original 'BaseStationID' column from the data frame
            df = df.drop('base_station_messages_id')

            # Add a column to the database of the list of base station ids
            base_station_id_column = pl.Series('base_station_messages_id', base_station_id_lst)
            df = df.with_columns(base_station_id_column)

            # print("\t\t + New column for base_station_ids added.")

        '''
        else:
            # Debugging time variables
            time_lst = ['ros_header_time', 'ros_header_seconds', 'ros_header_nanoseconds', 'written_to_bag_time']
            time_df = df.select(time_lst)
            print(f"Displaying the first 3 rows of time variables in this data frame: ")
            print(time_df.head(3))
        '''

        '''
        # Simple Debugging: Check How Data Frame Has Changed
        print("Updated Columns")
        print(df.columns)
        print(df.dtypes)
        # print(df.head(2))
        # print(db_col_lst)

        long_df = df.select("longitude")
        print(f"Displaying the first 3 rows of longitude variables in this data frame: ")
        print(long_df.head(3))

        print(len(df.columns))
        print(len(db_col_lst))
        '''

        # Ensure uniformity between the data frame columns and the db table columns. Change the names and reorder to match the db table
        if (len(db_col_lst) == len(df.columns)):
            # Reorder the columns to match with the db table layout
            new_column_order = db_col_lst
            df = df.select(new_column_order)
            # print(list(df.columns))   # Simple debugging, check whether columns match
        
        else:
            raise Exception("Error, the number of data frame columns is not the same as the number of database table columns.")

        return df

    except Exception as e:
        print(f"Error updating the data frame: {e}")