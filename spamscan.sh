#!/bin/sh

#######################
# (C) 2017 Steven Black
#######################
#
# 2017-05-17 - 1.0.0 Initial checkin of working script
# 2017-05-17 - 1.1.0 Major cleanup; fix retrain to "forget"
# 2017-05-17 - 1.2.0 No-sync flag added for spam & ham checks
# 2017-05-18 - 1.3.0 Process command line args for mailboxdir and backupdir
# 2017-05-20 - 1.4.0 Break into procedures; set default value for mailboxdir
# 2017-05-24 - 1.5.0 Add option for log directory
# 2017-05-25 - 1.5.1 Remove option for log directory
# 2017-05-27 - 1.5.2 Run sa-learn as user postfix
# 2017-05-28 - 1.5.3 Force ownership back to MailScanner defaults for Bayes dbs
# 2017-06-01 - 2.0.0 break it down into more discreet actions
#
#######################


# defaults
SCANSPAM=0
SCANHAM=0
SCANRETRAIN=0
DUMPBAYESINFO=0
BACKUPBAYESDB=0

# process the command line options
# the pattern  *must* be wrapped in quotes when passed in to avoid premature globbing
# the backup directory path is optional; no backup is performed if omitted
while getopts b:hH:im:rR:sS: OPTLABEL
do 
  case "$OPTLABEL" in
    b) BACKUPDIR="$OPTARG"
       ;;
    h) SCANHAM=1
       ;;
    H) SCANHAM=1; HAMDIR="$OPTARG"  
       ;;
    i) DUMPBAYESINFO=1
       ;;
    m) MAILBOXDIR="$OPTARG"
       ;;
    r) SCANRETRAIN=1
       ;;
    R) SCANRETRAIN=1; RETRAINDIR="$OPTARG"
       ;;
    s) SCANSPAM=1
       ;;
    S) SCANSPAM=1; SPAMDIR="$OPTARG" 
       ;;
    [?]) echo "Usage $0 [-i] [-m mailboxdir] [-b backupdir] [-h | -H hamdir] [-r | -R retraindir] [-s | -S spamdir]" >&2
        exit 1
        ;;
  esac
done

# If MAILBOXDIR isn't set (or is null), then use default value
MAILBOXDIR=${MAILBOXDIR:="/volume1/homes/*/.Maildir"}
MAILSERVER="/var/packages/MailServer/target"
MAILPERLLIB="${MAILSERVER}/lib/perl5" 
DBPATH="/var/spool/MailScanner/spamassassin"

# ensure requirements are met for making backup
verify_backup_dir () {
  if [ ! -z "$BACKUPDIR" ]; then
    if [ ! -d "$BACKUPDIR" ]; then
      echo "FATAL: Backup directory does not exist (\"$BACKUPDIR\")" >&2
      exit 1
    fi

    if [ ! -w "$BACKUPDIR" ]; then
      echo "FATAL: Unable to write to backup directory (\"$BACKUPDIR\")" >&2
      exit 1
    fi
  
    # backup prerequisites have been met; try to make backup
    BACKUPBAYESDB=1; 
  fi
}

# sync the bayes_journal file into the bayes token db
sync_bayes_db () {
  echo "Syncing Bayes DB"
  echo "Bayes DB location: \"$DBPATH\""

  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --sync
}

# scan mailboxes and learn as spam
scan_spam () {
  if [ -z "$SPAMDIR" ]; then
    SCANDIR="${MAILBOXDIR}/.Junk/{new,cur}"
  else
    SCANDIR="$SPAMDIR"
  fi

  echo "Scanning Spam folder(s)"
  echo "Spam path pattern: \"${SCANDIR}\""

  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --no-sync \
        --spam "${SCANDIR}"

  # The scan is performed with the no-sync option for improved speed
  # but the results still need to be eventually synced to the Bayes DB
  sync_bayes_db
}

# scan mailboxes and learn as ham
scan_ham () {
  if [ -z "$HAMDIR" ]; then
    SCANDIR="${MAILBOXDIR}/{new,cur}" 
  else
    SCANDIR="$HAMDIR"
  fi

  echo "Scanning Ham folder(s)"
  echo "Ham path pattern: \"${SCANDIR}\""

  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --no-sync \
        --ham "${SCANDIR}"

  # The scan is performed with the no-sync option for improved speed
  # but the results still need to be eventually synced to the Bayes DB
  sync_bayes_db
}

# scan mailboxes for any retraining (misidentified spam *or* ham)
scan_retrain () {
  if [ -z "$RETRAINDIR" ]; then
    SCANDIR="${MAILBOXDIR}/.Retrain/{new,cur}"
  else
    SCANDIR="$RETRAINDIR"
  fi

  echo "Scanning Retrain folder(s)"
  echo "Retraining path pattern: \"${SCANDIR}\"" 

  # "Forgetting" requires read/write access to the Bayes DB and 
  # manages its own syncing. No need to explicitly sync afterwards
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --forget "${SCANDIR}"
}

# print out the status of the bayes db
dump_bayes_info () {
  echo "Current Bayes Info"
  echo "Bayes DB location: \"$DBPATH\""

  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --dump magic
}

# make a backup copy of the bayes db
backup_bayes_db () {
  echo "Backing up SpamAssassin DB"
  echo "Backup Bayes DB location: \"${BACKUPDIR}/spamassassin.backup\""

  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --backup > "${BACKUPDIR}/spamassassin.backup"
}

# Run prerequisite checks before proceeding with scan
if [ -n $BACKUPDIR ]; then verify_backup_dir; fi

echo "==== Scan Start: $(date) ===="

if [ $SCANSPAM -ne 0 ]; then scan_spam; fi
if [ $SCANHAM -ne 0 ]; then scan_ham; fi
if [ $SCANRETRAIN -ne 0 ]; then scan_retrain; fi
if [ $BACKUPBAYESDB -ne 0 ]; then backup_bayes_db; fi
if [ $DUMPBAYESINFO -ne 0 ]; then dump_bayes_info; fi

# Make sure set ownership back to the default so that
# the MailScanner service can access the database
chown postfix:root "${DBPATH}"/bayes_*
chmod 666 "${DBPATH}"/bayes_*

echo "==== Scan Complete: $(date) ===="

exit 0
