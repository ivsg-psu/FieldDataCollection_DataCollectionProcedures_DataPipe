'''
    ====================================== Class Database =========================================
    #	Purpose: Create a class Database to access the SQL database and perform
    #   simple queries related to creating data frames (df).
    #
    #   Methods:
    #       1. def __init__(self, username, password, server, port, db_name)
    #           Establish a connection to the SQL database and create a cursor.
    #           Takes a username, password, server, port, and database name as inputs.
    #  
    #       2. def get_tables(self)
    #           Returns a list of all the tables in the database.
    #
    #       3. def insert_and_return(self, table_name, col_lst, val_lst)
    #           Insert a new row into a specific table. Accepts a table to insert to,
    #           the columns where data will be added, and the values to add to those
    #           columns as inputs. Returns the id of this newly created entry.
    #           Query: INSERT INTO table_name (cols) VALUES (vals) RETURNING id;
    #
    #       4. def select(self, table_name, col1, col2, val)
    #           Select a singular row from a specific table and return the id of
    #           this row.
    #           Query: SELECT col1 FROM table_name WHERE col2 = 'val';
    # 
    #       5. def select_multiple(self, table_name, col, val)
    #           Used for reading from the database. Select multiple rows from a table
    #           where the bag file has a certain name. Create a data frame out of these rows.
    #           Query: SELECT * FROM table_name WHERE bag_file_id = val;
    #    
    #       6. def df_to_db(self, table_name, df, db_col_lst)
    #           Quickly insert a data frame into the database. Convert the data frame into a CSV
    #           string, then use copy_expert.
    #           Query: COPY table_name (db_col_lst) FROM STDIN WITH CSV HEADER NULL AS 'NULL'
    #                  cursor.copy_expert(sql = query, file = csv_buffer)
    # 
    #       7. def delete(self, table_name, id)
    #           A simple method to delete a row from a table.
    #           Query: DELETE FROM table_name WHERE id = id;
    #
    #       8. def disconnect(self)
    #           Disconnect from the database by closing the cursor, committing the connection,
    #           and closing the connection.
    #
    # 	Author: Sadie Duncan
    # 	Date:   08/09/2024
    
    make sure psycopg2, pandas, polars are installed
    ===============================================================================================
'''
from io import StringIO
import sys
import psycopg2
import pandas as pd
import polars as pl
import numpy as np
import time

from psycopg2 import sql
import parse_utilities
from get_table_info import get_table_info
from write_csv import write_csv

class Database:
    # Upon initialization of the database instance, establish a connection to the SQL 
    # database and create a cursor.
    def __init__(self, connect_to_db, db_url):
        if (connect_to_db == 1):
            try:
                self.conn = psycopg2.connect(db_url)
                self.cursor = self.conn.cursor()
                print("PostgreSQL connection is open.")
                
            except psycopg2.Error as e:
                print(f"\nUnable to connect to the database: {e}")
                self.conn = None
                self.cursor = None
                sys.exit()
                
        else:
            self.conn = None
            self.cursor = None
            print("Class instance of database made. However, PostgreSQL connection is not established.")

    def get_db_size(self, db_name):
        try:        
            cursor = self.cursor
            conn = self.conn
            
            cursor.execute("SELECT pg_database_size(%s)", (db_name,))

            db_size_bytes = cursor.fetchone()[0]
            db_size_mb = round((db_size_bytes / (1024 * 1024)), 4)

            return db_size_bytes, db_size_mb

        except psycopg2.Error as e:
            print(f"\t - Error finding database size: {e}")
            conn.rollback()
    
    def get_tables(self, to_print_count):
        try:
            cursor = self.cursor
            conn = self.conn
            
            schema = "public"
            query = sql.SQL("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = %s
            """)
            
            cursor.execute(query, (schema,))
            
            tables = []
            for table in cursor.fetchall():
                tables.append(table[0])
              
            if (to_print_count == 1):  
                for table in tables:
                    count_query = sql.SQL("SELECT COUNT(*) FROM {}").format(
                        sql.Identifier(table)
                    )
                    
                    cursor.execute(count_query)
                    count = cursor.fetchone()[0]
                    print(f"\t'{table}': {count}") 
                    
            return tables 

        except psycopg2.Error as e:
            print(f"\t - Unable to fetch tables: {e}")
            conn.rollback()

    '''
    Insert a new row into a specific table. Accepts a table to insert to, the columns where data will be 
    added, and the values to add to those columns as inputs. Returns the id of this newly created entry.
    Query: INSERT INTO table_name (cols) VALUES (vals) RETURNING id;
    '''
    def insert_new_bag(self, bag_file_name):
        try:
            cursor = self.cursor
            conn = self.conn
            
            # Build and execute the query
            insert_query = """INSERT INTO bag_files (bag_file_name) VALUES (%s) RETURNING id;"""
            
            cursor.execute(insert_query, (bag_file_name,))

            # Get the id of the row that was just added. Return this value
            inserted_id = cursor.fetchone()[0]
            print(f"\n+ New bag file entry inserted into bag files table with id = {inserted_id}\n")
            
            return inserted_id

        except psycopg2.Error as e:
            print(f"\t - Unable to insert into the database: {e}")
            conn.rollback()

    def get_bag_id_from_name(self, bag_file_name):
        try:
            cursor = self.cursor
            conn = self.conn
            
            # Build and execute the query
            insert_query = """SELECT id FROM bag_files WHERE bag_file_name = %s;"""
            
            cursor.execute(insert_query, (bag_file_name,))
            
            result = cursor.fetchone()
            
            if result:
                bag_id = result[0]
                return bag_id
            
            else:
                return None

        except psycopg2.Error as e:
            print(f"\t - Unable to insert into the database: {e}")
            conn.rollback()
            
    def check_bag_id(self, id):
        try:
            cursor = self.cursor
            conn = self.conn

            cursor.execute("SELECT EXISTS (SELECT 1 FROM bag_files WHERE id = %s)", (id,))
            result = cursor.fetchone()[0]  # Returns True or False
            return result   
            
        except psycopg2.Error as e:
            print(f"\t - Wrror: {e}")
            conn.rollback()
            
    def get_base_station_id(self, base_station_name):
        try:
            cursor = self.cursor
            conn = self.conn
            
            # Build and execute the query
            insert_query = """SELECT id FROM base_station_messages WHERE base_station_name = %s;"""
            
            cursor.execute(insert_query, (base_station_name,))
            
            result = cursor.fetchone()
            
            if result:
                base_station_id = result[0]
                return base_station_id
            
            else:
                # Build and execute the query
                insert_query = """INSERT INTO base_station_messages (base_station_name) VALUES (%s) RETURNING id;"""
                
                cursor.execute(insert_query, (base_station_name,))

                # Get the id of the row that was just added. Return this value
                base_station_id = cursor.fetchone()[0]
                
                return base_station_id
        
        except psycopg2.Error as e:
            print(f"\t - Unable to fetch or insert base station id: {e}")
            conn.rollback()
            
    '''
    Quickly insert a data frame into the database by converting the data frame into a CSV string, then using copy_expert.
    Query: COPY table_name (db_col_lst) FROM STDIN WITH CSV HEADER NULL AS 'NULL'
           cursor.copy_expert(sql = query, file = csv_buffer)
    '''
    def df_to_db(self, table_name, df, db_col_lst):
        try:
            cursor = self.cursor
            conn = self.conn

            # Convert the data frame into a Pandas data frame and then into a CSV string to work with copy_expert
            pd_df = df.to_pandas()

            csv_buffer = StringIO()
            pd_df.to_csv(csv_buffer, index = False, header = True, sep = ",", na_rep = 'null')
            csv_buffer.seek(0)           # Rewind the buffer to the beginning for reading
            # print(csv_buffer.read())   # For simple debugging, print the CSV string to ensure it's not empty

            # Build the query
            query = sql.SQL("COPY {} ({}) FROM STDIN WITH CSV HEADER NULL AS 'null'").format(
                sql.Identifier(table_name),
                sql.SQL(', ').join(map(sql.Identifier, db_col_lst))
            )

            # Use copy_expert to transport the data into the database
            cursor.copy_expert(sql = query, file = csv_buffer)
            # print(f"\t + The data frame has successfully been inserted into {table_name}.")

        except psycopg2.Error as e:
            print(f"\t - Unable to write the data frame into the database: {e}")
            conn.rollback()

    def db_to_df (self, bag_id, table):
        try:
            cursor = self.cursor
            conn = self.conn
            
            # For each topic, create a data frame based off of the bag_file id - will create a data frame of all the data from 
            # the same bag file id
            # table_name, mapping_dict, db_col_lst = get_table_info(table)
            
            query = sql.SQL("""SELECT * FROM {} WHERE bag_file_db_id = %s""").format(
                sql.Identifier(table)
            )

            cursor.execute(query, (bag_id,))
            
            df = pd.DataFrame(cursor.fetchall(), columns = [col[0] for col in cursor.description])
            
            if (df.empty):
                print("Error creating data frame.\n")
                return None
            
            else:
                print(f"\nTotal size of '{table}' for the bag file with id = {bag_id}: {df.shape}")
                print(f"Displaying the first 3 rows of '{table}:")
                print(df.head(3))
                
                return df

        except psycopg2.Error as e:
            print(f"\nError creating dataframe: {e}")
            conn.rollback()

    '''
    Used for reading from the database. Select multiple rows from a table where the bag file has a certain name.
    Create a data frame out of these rows. Return the data frame.
    Query: SELECT * FROM table_name WHERE bag_file_id = val;
    '''
    def select_multiple(self, table_name, col, val):
        try:
            cursor = self.cursor
            conn = self.conn

            # Build and execute query
            select_query = sql.SQL("SELECT * FROM {} WHERE {} = %s").format(
                sql.Identifier(table_name),
                sql.Identifier(col)
            )
            
            cursor.execute(select_query, (val,))

            # Create rows of data out of the selected items
            rows = cursor.fetchall()

            # Create a list of columns using the cursor.description
            columns = [header[0] for header in cursor.description]

            # Create a Pandas data frame out of the above. Then transform it into a Polars data frame
            pd_df = pd.DataFrame(rows, columns = columns)
            df = pl.from_pandas(pd_df)

        except psycopg2.Error as e:
            df = pl.DataFrame()
            print(f"\t - Unable to select from the database: {e}")
            conn.rollback()

        return df   # Return the data frame
    
    def check_and_commit(self, db_name):
        try:
            cursor = self.cursor
            conn = self.conn

            db_size_bytes, db_size_mb = self.get_db_size(db_name)
            print(f"The database is currently {db_size_bytes} bytes ({db_size_mb} MB).")
            tables = self.get_tables(1)
            print("-" * 150)

            conn.commit()

        except psycopg2.Error as e:
            print(f"\t - Error commiting: {e}")
            conn.rollback()

    '''
    Method to delete a row from a table.
    Query: DELETE FROM table_name WHERE id = id;
    '''
    def delete(self, id):
        try:
            cursor = self.cursor
            conn = self.conn

            tables = self.get_tables(0)
            
            for table in tables:
                column_check_query = """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = %s AND column_name = %s
                """
                cursor.execute(column_check_query, (table, "bag_file_db_id"))
                result = cursor.fetchone()

                if result:
                    delete_query = sql.SQL("DELETE FROM {} WHERE bag_file_db_id = %s").format(
                        sql.Identifier(table)
                    )
                    
                    cursor.execute(delete_query, (id,))
                    # print(f"\t\tDeleting rows from '{table}' where bag file id = {id}")
                
            cursor.execute("""DELETE FROM bag_files WHERE id = %s""", (id,))
            
            conn.commit()
            # print(f"\tSuccessfully deleted all data where bag file id = {id}")

        except psycopg2.Error as e:
            print(f"\t - Unable to delete from the database: {e}")
            conn.rollback()
    
    '''
    Disconnect from the database by closing the cursor, committing the connection, and closing the connection.
    '''
    def disconnect(self):
        cursor = self.cursor
        conn = self.conn

        cursor.close()
        conn.commit()
        conn.close()
        print("PostgreSQL connection is closed.")

def check_bag_name_id(db):
    bag_id = 0
            
    bag = input("Enter the name or id of the bag file you'd like to focus on: ")
    try:
        bag_id = int(bag)
            
    except:
        bag_id = db.get_bag_id_from_name(bag)
        
        if (bag_id == None):
            print(f"No entry found for bag file named: '{bag}'")
    
    bag_id_exist = db.check_bag_id(bag_id)
    
    if (bag_id_exist == False):
        print(f"No entry found for bag file with id: '{bag_id}'")
        bag_id = 0
    
    return bag_id
    

def main():
    start_time = time.time()
    
    to_csv = 1
    to_db = 1
    
    if (to_db != 1):
        sys.exit()

    # Database login parameters for the new database computer:
    db_username = "postgres"
    db_password = "pass"
    db_server   = "127.0.0.1"
    db_port     = "5432"
    
    # Try connecting to the database. The script will end if connection fails
    try:
        db_name = input("Please enter the name of the database you'd like to connect to: ")
        db = Database(to_db, db_username, db_password, db_server, db_port, db_name)
    
    except:
        print("Error connecting to the database. Please check database connection parameters.")
        sys.exit()

    menu = """\nPlease select a database option from the menu.
        1. Return a list of available database tables
        2. Insert a new bag file id into a table
        3. Check for a specific bag file
        4. Check specific table
        5. Delete all data from a specific bag file
        6. Display the current database size
        7. Display the current tables and table entry counts
        8. Disconnect and end session\n"""
        
    while True:
        print(menu)
        user_input = input("Enter your choice: ")
        print()

        if (user_input == "1"):
            db_tables = db.get_tables(0)   
            print(f"The database currently has the following {len(db_tables)} tables: {db_tables}")

        elif (user_input == "2"):
            bag_name = input("Enter the name of the bag file you'd like to insert: ")
            
            print("Inserting new bag file.")
            bag_id = db.insert_new_bag(bag_name)
            
        elif (user_input == "3"):
            bag_id = check_bag_name_id(db)
            if (bag_id != 0):
                print("The bag file exists.\n")
                
            else:
                print("The bag file does not exist.\n")
                
        elif (user_input == "4"):
            bag_id = check_bag_name_id(db)
            if (bag_id != 0):
                table_name = input("Enter the name of the table you'd like to examine: ")
                db_tables = db.get_tables(0)
                
                if (table_name not in db_tables):
                    print("Error, table does not exist.\n")
            
                else:
                    df = db.db_to_df(bag_id, table_name)

        
        elif (user_input == "5"):
            bag_id = check_bag_name_id(db)
            if (bag_id != 0):
                db_size_bytes, db_size_mb = db.get_db_size(db_name)
                print(f"\nBefore Deletion: Database Size = {db_size_bytes} bytes ({db_size_mb} MB)\n")
                db_tables = db.get_tables(1)

                db.delete(bag_id)
                
                db_size_bytes2, db_size_mb2 = db.get_db_size(db_name)
                print(f"\nAfter Deletion: Database Size = {db_size_bytes2} bytes ({db_size_mb2} MB)\n")
                db_tables = db.get_tables(1)
        
        elif (user_input == "6"):
            db_size_bytes, db_size_mb = db.get_db_size(db_name)
            print(f"Current Database Size: {db_size_bytes} bytes ({db_size_mb} MB)")
        
        elif (user_input == "7"):
            print("The database currently has the following number of entries in each table:")
            db_tables = db.get_tables(1)
        
        elif (user_input == "8"):
            print("Exiting session.\n")
            db.disconnect()
            break

        else:
            print("Invalid choice. Please try again.")
         
    end_time = time.time()
    total_time = round((end_time - start_time), 4)
    print(f"\nSession Runtime: {total_time}")
    print("─" * 100)

# Call the main() function  
if __name__ == "__main__":
    main()
    
'''
df_count = 0   # Keep track of the number of data frames created

            for table in tables:
                print("-" * 150)
                print(f"Now working on the following table: {table}")
                topic_start_time = time.time()

                # For each topic, create a data frame based off of the bag_file id - will create a data frame of all the data from 
                # the same bag file id
                # table_name, mapping_dict, db_col_lst = get_table_info(table)
                
                query = sql.SQL("""SELECT * FROM {} WHERE bag_files_id = %s""").format(
                    sql.Identifier(table)
                )

                cursor.execute(query, (bag_id,))
                
                df = pd.DataFrame(cursor.fetchall(), columns = [col[0] for col in cursor.description])

                print(f"\nTotal size of '{table}' for the bag file with id = {bag_id}: {df.shape}")
                print(f"Displaying the first 3 rows of '{table}:")
                print(df.head(3))
                df_count += 1
                
                # Write a CSV file
                if (to_csv == 1):                   
                    folder = bag_name[:-4]         # Getting the folder name by cutting off the '.bag'
                    write_csv(folder, table, df)
                            
                topic_end_time = time.time()
                topic_total_time = topic_end_time - topic_start_time
                print(f"Time to read/write '{table}': {topic_total_time} seconds")
                
            if (df_count > 0):
                print(f"Total data frames created: {df_count}")
'''
