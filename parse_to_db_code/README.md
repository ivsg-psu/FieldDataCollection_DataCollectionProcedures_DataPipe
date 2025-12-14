# Parse to Bag Files or CSV Files and Upload to Database
## Table of Contents
- [Overview](#overview)
- [Set-Up Guide](#set-up-guide)
- [User Guide](#user-guide)
   - [Using the Database](#using-the-database)
   - [Using the Python Script](#using-the-python-script)
- [Check Results and Exit](#check-results-and-exit)
- [Postgres with Python](#postgres-with-python)
- [Postgres Cheatsheet](#postgres-cheatsheet)
   - [Select Queries](#select-queries)
- [Python Installation](#python-installation)
- [Troublshooting](#troubleshooting)

- - - -
## Overview

- - - -

##  Set-Up Guide
[↑ Back to Top](#table-of-contents)

1. Make sure you are using at least Python 3.8 or higher:
```
python3 --version
```
2. Refer to [Python Installation](#python-installation) if you need to upgrade your Python version
3. Clone the repository
4. Open a terminal and 'cd' into the location of the `parse_to_db_code` folder:
```
cd C:\Users\USER\Documents\GitHub\FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase\parse_to_db_code
```
5. Install all dependencies:
```
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
```
6. Check if dependencies were properly installed:
```
python3 -m pip list
```

- - - -

## User Guide
[↑ Back to Top](#table-of-contents)

### Using the Database
1. Open a terminal
2. Switch to a Postgres role:
```bash
sudo -i -u postgres
```
3. Launch the PostgreSQL server:
```
psql
```
4. Display the current databases: `\l`
   1. To exit out of this view (if needed): `q`
5. Go to the desired database: `sql\c <database_name>;`
   1. Example: `\c updated_mapping_van_raw;`
   2. To go back to the main Postgres screen: `\c postgres;`, or `q` and `psql`
   3. Refer to [Postgres Cheatsheet](#postgres-cheatsheet) for more information about creating a new database and other Postgres commands

### Using the Python Script
6. Open another terminal
7. "cd" into the location of the parsing script
```
cd C:\Users\USER\Documents\GitHub\FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase\parse_to_db_code
```
8. Open the `parse_and_insert_v4.py` script and set the script parameters
   1. Whether to read the bag files
   2. Specific topics to check
   3. Whether to write the time logs
   4. What data types to parse
   5. Where to save/write the data
   6. Database login information and topics
9. Determine a source (the location of the bag files to parse)
10. Determine a destination (the location of where to save the CSV or hash folders associated with the bag files)
11. Run the script:
```
python3 parse_and_insert_v4.py -s '<source>' -d '<destination>'
python3 parse_and_insert_v4.py -s '<source>' -d '<destination>' -a
python3 parse_and_insert_v4.py -s '<source>' -d '<destination>' -f '<fileName>'
```

### Check Results and Exit
12. For common SQL commands/queries, refer to [Postgres Cheatsheet](#postgres-cheatsheet)
13. To exit:
   1. Exit psql server: `\q`
   2. Exit Postgres: `exit`

- - - -

## Postgres Cheatsheet
[↑ Back to Top](#table-of-contents)

### Postgres Sections
- [Access Postgres](#access-postgres)
- [Upload New SQL Script](#upload-new-sql-script)
- [Change Database Attributes](#change-database-attributes)
- [Postgres Basic Commands](#postgres-basic-commands)
- [Table Commands and Basic Queries](#table-commands-and-basic-queries)
- [Write Queries to a File](#write-queries-to-a-file)
- [Select Queries](#select-queries)

### Access Postgres
[↑ Back to Sections](#postgres-sections)

1. Open a terminal
2. Switch to a Postgres role:
```bash
sudo -i -u postgres
```
3. Enter user password
4. Launch the PostgreSQL server:
```
psql
```
5. Display the current databases: `\l`
   1. To exit out of this view (if needed): `q`
6. Go to the desired database: `sql\c <database_name>;`
   1. Example: `\c updated_mapping_van_raw;`
   2. To go back to the main Postgres screen: `\c postgres;`, or `q` and `psql`
7. To exit:
   1. Exit psql server: `\q`
   2. Exit Postgres: `exit`

### Upload New SQL Script
[↑ Back to Sections](#postgres-sections)

* General template for running commands from a file (in the database itself): `\i <file-name>` 
* Upload the SQL script from the psql server (in the database itself):
```sql
-- Template: \i <path_to_script>/<sql_script>.sql;
\i /home/USER/Documents/GitHub/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/SQL_Scripts/create_raw_data_db.sql;
```
* Upload the SQL script from a terminal server:
```sql
-- Template: sudo -u <user> psql -d <db-name> -a -f <path_to_sql_script>.sql
sudo -u postgres psql -d testdb -a -f create_raw_data_db.sql;
sudo -u postgres psql -d testdb -a -f /home/USER/Documents/GitHub/FieldDataCollection_DataCollectionProcedures_ParseRawDataToDatabase/SQL_Scripts/create_raw_data_db.sql;
```

### Change Database Attributes
[↑ Back to Sections](#postgres-sections)

* Change database password:
```sql
ALTER USER <user> WITH PASSWORD '<new-password>;'
```
* Change database name:
```sql
ALTER DATABASE <name> RENAME TO '<new-name>;'
```

### Postgres Basic Commands
[↑ Back to Sections](#postgres-sections)

| Description  | Command |
| ------------- | ------------- |
| Clear Screen | <kbd>ctrl + l</kbd> |
| Exit out of a view | <kbd>q</kbd> |
| List all databases | `\l` |
| Switch to another database  | `\c <database_name>;`  |
| Create a database | `CREATE DATABASE <database_name>` |
| Delete a database | `DROP DATABASE <database_name>` |
| List all schemas | `\dn` |
| List users | `\du` or `\du <username>` |
| List all functions | `\df` |
| List all views | `\dv` |
| Change display mode | `\x` (to turn on and off) |

### Table Commands and Basic Queries
[↑ Back to Sections](#postgres-sections)

| Description  | Command |
| ------------- | ------------- |
| List database tables | `\dt` |
| List all database relations |  `\d` |
| View table information (constraints, references, etc.) | `\d <table_name>` or `\d+ <table-name>` |

* View a table
```sql
TABLE <table_name>;
```
* Find the # of entries from a table
```sql
SELECT COUNT (*) FROM <table_name>;
```
* Check if data exists (returns true or false)
```sql
SELECT EXISTS (<select_statement>); 
```
* Create a table
```sql
CREATE TABLE <table-name> (
   id int NOT NULL DEFAULT 1,
   name char(11)  NOT NULL DEFAULT 'mapping van',
   CONSTRAINT vehicle_pk PRIMARY KEY (id),
   CONSTRAINT vehicle_ck CHECK (id = 1) 
);
```
* Delete table:
```sql
DROP TABLE <table_name>;
```
* Insert a new row into a table
```sql
-- Template: INSERT INTO <table_name> (<table_columns>) VALUES (<data_to_insert>)
-- Example:
INSERT INTO bag_files (bag_file_name) VALUES ('mapping_van_2024-11-26-15-00-03_0') RETURNING id;
```
* Check database size
```sql
SELECT pg_database_size('database_name');
```
* View a database's tables (as a query)
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
```

### Write Queries to a File
[↑ Back to Sections](#postgres-sections)

First, open a terminal, "cd" to the directory where you'd like to store this file. Then, run the following:
```sql
\o <file_name>;
-- Queries
\o
```
Use `\o` to begin saving results to a chosen file and `\o` again to stop saving results to the file. Note: if this setting is used, the query outputs will not be shown on the terminal, but can be checked in the file.

### Select Queries
* Check database size
```sql
SELECT pg_database_size('database_name');
```
* View a database's tables
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
```
* Insert a new row into a table
```sql
-- Template: INSERT INTO <table_name> (<table_columns>) VALUES (<data_to_insert>)
-- Example:
INSERT INTO bag_files (bag_file_name) VALUES ('mapping_van_2024-11-26-15-00-03_0') RETURNING id;
```
* Check if data exists (returns true or false)
```sql
SELECT EXISTS (<select_statement>); 
```
* Select data

- - - -

## Python Installation
[↑ Back to Top](#table-of-contents)

During the summer of 2024, it was discovered Python 3.10 was required to use Velodyne_Decoder-2.3.0 due to issues with the latest version. Those issues have since been fixed, meaning it is no longer necessary to only use V2.3.0. Thus, the minimum required Python version is 3.9. The rest of this tutorial will use Python 3.12.

The following was completed to install a newer version of Python on Ubuntu from this guide: https://phoenixnap.com/kb/how-to-install-python-3-ubuntu

1. Open a terminal
2. Check the current Python version:
```
python3 --version
```
3. If you have a version higher than Python 3.9, you can skip the rest of this section
4. If you do not have a version higher than Python 3.9, first, update local package repositories and install any needed software
```bash
sudo apt update
sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
```
5. "cd" into the `/tmp` directory
```
cd /tmp
```
6. Visit: https://www.python.org/downloads/source/
7. Determine the Python version you want to download (Python 3.9 or higher), right-click on the Gzipped source tarball link, and "Copy Link"
8. Download this file into the `/tmp` directory
```
wget https://www.python.org/ftp/python/3.12.10/Python-3.12.10.tgz
```
9. Extract the compressed files. You will now have a new directory named after the Python version installed:
```
tar -xf Python-3.12.10.tgz
```
10. Test the system and optimize before installing:
```
cd Python-3.12.10
./configure --enable-optimizations
```
11. Install this new Python version:
    1. Note: This might take a few minutes.
```
sudo make install
```
12. Verify the installation worked. You should now see the newly installed version:
```
python3 --version
```

- - - -

## Troubleshooting
[↑ Back to Top](#table-of-contents)

* If any issues occur, please check the Documents_OLD folder (in the Documents folder).
* Feel free to contact Sadie Duncan (<sed5658@psu.edu>) with any questions.
* For more information, refer to:
  * Old database schema, how to download PostgreSQL and Python: https://github.com/ivsg-psu/Databases_DatabaseSchemaDesign_PostgreSQLServerSetup/wiki
  * How to download PostgreSQL: https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart
  * More Postgresql commands:
    * https://github.com/ivsg-psu/Databases_SettingUpAndConnectingToDatabases_ConstructMappingVanDatabase
    * https://hasura.io/blog/top-psql-commands-and-flags-you-need-to-know-postgresql
    * https://www.postgresql.org/docs/current/app-psql.html
   
- - - -

## Authors
[↑ Back to Top](#table-of-contents)

Sadie Duncan (<sed5658@psu.edu>)

