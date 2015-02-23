# mysql.xdb.cleanup.sh
Xtrabackup addition to clean up the xdb  bitmap log files
USAGE:

Add the mysql.xdb.cleanup.sh at the end of you Innobackupex/Xtrabackup script 
Make sure the following variables are set properly:
BACKUPUSER="USED_XTRABACKUP_USER"
BACKUPUSERPWD="USED_XTRABACKUP_PASSWD"
XTRABACKUP_CHECKPOINTS_PATH="THE DIRECTORY WHERE THE LATEST INCREMETAL OR FULL BACKUP WAS DONE"
DEBUG=1 # or 0 to disable it
MOVE_INSTEAD_OF_DELETE=1 # or 0 delete the xdb files, the xdm files will be stored at the latest xtrabacup directory in XDB_BACKUP and compressed
DRY_RUN=1 # ot 0 to clean up the xdb files in real

