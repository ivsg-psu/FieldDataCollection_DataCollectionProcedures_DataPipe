import os
import pandas as pd
import datetime

def overview(batch_size, csv_flag, db_flag):
    batch_name = input("Please enter a name for this batch of data: ")
    
    start_datetime = datetime.datetime.now()
    start_day = start_datetime.strftime("%x")
    start_time = start_datetime.strftime("%X")
    
    # Make time more specific, add fractions of seconds
    
    # total file start time vs. specific file start time

    batch_overview = [batch_name, start_day, start_time, csv_flag, db_flag, batch_size]
    return batch_overview

def init_new_row(batch_overview):
    new_row = {}

    batch_overview_cols = ["Test Name", "Start Date", "Start Time", "Wrote CSV", "Wrote to DB", "Test File Count"]
    
    result_cols = ["File #", "Bag File Name", "Bag File Size (MB)", "Data Type",
                  "Parse Time (s)", "Parse Throughput (MB/s)",
                  "Data Frame Size (MB)", "DB Upload Time (s)", "DB Throughput (MB/s)",
                  "File Runtime (s)", "File Throughput (MB/s)"] 
    
    csv_cols = batch_overview_cols + result_cols

    for i in range (0, len(csv_cols), 1):
        if (i < len(batch_overview_cols)): 
            new_row[csv_cols[i]] = batch_overview[i]
        
        else:
            new_row[csv_cols[i]] = None

    return new_row
    
def update_new_row(row, key, val):
    row[key] = val
        
    return row

def write_row(to_db, row):
    if (to_db == 1):
        time_log_name = "IVSG_parse_and_insert_time_logs.csv"
    else:
        time_log_name = "IVSG_parse_and_insert_to_db_time_logs.csv"
    
    df = pd.DataFrame([row])
    
    if not os.path.exists(time_log_name):
        df.to_csv(time_log_name, index = False, header = True)
        
    else:
        df.to_csv(time_log_name, mode = "a", index = False, header = False)