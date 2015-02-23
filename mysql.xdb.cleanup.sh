#!/bin/bash
# Mon Feb 23 01:27:55 CET 2015
# done by seikath@gmail.com
# Custom made MariaDB/Mysql/Percona  backup script using xtrabackup comes first
# More info abvout the XTRADB CHANGED PAGE TRACKING you may find here 
# http://www.percona.com/doc/percona-server/5.5/management/changed_page_tracking.html 
# All you have to do os to include that script and to use the proper configuration values ..
# =======================================================================================================================================================

# here starts the clean up the ib_modified_log_XX_XXX.xdb files 
# last modified: Fri Feb 13 03:45:12 CET 2015 
# done by seikath
BACKUPUSER="XTRABACKUP_USER"
BACKUPUSERPWD="XTRABACKUP_PASSWD"
XTRABACKUP_CHECKPOINTS_PATH="THE DIRECTORY WHERE THE LATEST INCREMETAL OR FULL BACKUP WAS DONE"
here=$(pwd) # remember which is the recent directory
DEBUG=1 # or 0 to disable it
MOVE_INSTEAD_OF_DELETE=1 # or 0 delete the xdb files, the xdm files will be stored at the latest xtrabacup directory in XDB_BACKUP and compressed
DRY_RUN=1 # ot 0 to clean up the xdb files in real
# check the config values, make sure they are valid and not empty 
test -z "$DRY_RUN" && DRY_RUN=1
test -z "$MOVE_INSTEAD_OF_DELETE" && MOVE_INSTEAD_OF_DELETE=1
test -z "$DEBUG" && DEBUG=1
# store here the last LSN after a successful backup
LAST_LSN=""
SKIP_FIRST=1 # fix for a https://bugs.launchpad.net/percona-server/+bug/1260035
XDB_TO_DELETE="" # fix for a https://bugs.launchpad.net/percona-server/+bug/1260035
# get the mysql data directory
DATA_DIR=$(mysql -BN -u ${BACKUPUSER} p${BACKUPUSERPWD} -e "show global variables like 'datadir';" | cut -f 2)
XDB_BACKUP_DIR=$(dirname ${XTRABACKUP_CHECKPOINTS_PATH})
test $MOVE_INSTEAD_OF_DELETE -eq 1 && test $DRY_RUN -ne 1 && test ! -d "${XDB_BACKUP_DIR}/XDB_BACKUP" && mkdir "${XDB_BACKUP_DIR}/XDB_BACKUP"
LAST_LSN=$(grep last_lsn ${XTRABACKUP_CHECKPOINTS_PATH} | sed 's/^.*= *//;s/ *$//')
cd ${DATA_DIR} && ls -lrt  \
| grep  "ib_modified_log_[[:digit:]]*_[[:digit:]]*.xdb" \
| sed 's/^.*ib_modified_log_/ib_modified_log_/' \
| sort -V \
| sed '$d' \
| while read XDBFILE
do
	FILE_START_LSN=$(echo ${XDBFILE} | sed 's/^ib_modified_log_[[:digit:]]*_//;s/[^[:digit:]]//g');
	test $DEBUG -ge 1 && echo "$(date):[debug] : checking if last backuped LSN ${LAST_LSN} at ${XTRABACKUP_CHECKPOINTS_PATH} is greater than the LSNs in ${XDBFILE}"
	if [ $MOVE_INSTEAD_OF_DELETE -eq 1 ]
	then
		test $DEBUG -ge 1 \
			&& test $SKIP_FIRST -eq 1 \
			&& test $LAST_LSN -gt $FILE_START_LSN \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& echo "$(date):[debug] : skip moving ${DATA_DIR}/${XDBFILE} as we have to check the next xdb file" \
			&& SKIP_FIRST=0 \
			&& continue
		test $SKIP_FIRST -eq 1 \
			&& test $LAST_LSN -gt $FILE_START_LSN \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& SKIP_FIRST=0 \
			&& continue
		test $DEBUG -ge 1 \
			&& test $LAST_LSN -gt $FILE_START_LSN \
			&& test $SKIP_FIRST -ne 1 \
			&& echo "$(date):[debug] : moving and compressing ${DATA_DIR}/${XDB_TO_DELETE} as ${LAST_LSN} > $FILE_START_LSN"
		test $LAST_LSN -gt $FILE_START_LSN \
			&& test $SKIP_FIRST -ne 1 \
			&& test $DRY_RUN -ge 1 \
			&&  echo "$(date):[dry run] : you should move and compress ${XDB_TO_DELETE} to ${XDB_BACKUP_DIR}/XDB_BACKUP" \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& continue
		test $LAST_LSN -gt $FILE_START_LSN \
			&& test $SKIP_FIRST -ne 1 \
			&& mv -v "${XDB_TO_DELETE}" "${XDB_BACKUP_DIR}/XDB_BACKUP" \
			&& gzip "${XDB_BACKUP_DIR}/XDB_BACKUP/${XDB_TO_DELETE}" \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& continue
	else
		test $DEBUG -ge 1 \
			&& test $SKIP_FIRST -eq 1 \
			&& test $LAST_LSN -gt $FILE_START_LSN \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& echo "$(date):[debug] : skip deletingg ${DATA_DIR}/${XDBFILE} as we have to check the next xdb file" \
			&& SKIP_FIRST=0 \
			&& continue
		test $SKIP_FIRST -eq 1 \
			&& test $LAST_LSN -gt $FILE_START_LSN \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& SKIP_FIRST=0 \
			&& continue
		test $DEBUG -ge 1 \
			&& test $LAST_LSN -gt $FILE_START_LSN \
			&& test $SKIP_FIRST -ne 1 \
			&& echo "$(date):[debug] : deletingg ${DATA_DIR}/${XDB_TO_DELETE} as ${LAST_LSN} > $FILE_START_LSN"
		test $LAST_LSN -gt $FILE_START_LSN \
			&& test $SKIP_FIRST -ne 1 \
			&& test $DRY_RUN -ge 1 \
			&&  "$(date): [dry run] : you should delete ${DATA_DIR}/${XDB_TO_DELETE}" \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& continue
		test $LAST_LSN -gt $FILE_START_LSN \
			&& test $SKIP_FIRST -ne 1 \
			&& rm  -v "${XDB_TO_DELETE}" \
			&& XDB_TO_DELETE="${XDBFILE}" \
			&& continue
	fi
done
cd "${here}" # get back to the original location
# here ends the clean up the ib_modified_log_XX_XXX.xdb files 



