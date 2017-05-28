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
#
#######################


# process the command line options
# the mailbox directory pattern *must* be specified
# the pattern  *must* be wrapped in quotes when passed in to avoid premature globbing
# the backup directory path is optional; no backup is performed if omitted
while getopts m:b: OPTLABEL
do 
  case "$OPTLABEL" in
    m) MAILBOXDIR="$OPTARG";;
    b) BACKUPDIR="$OPTARG";;
    [?]) echo "Usage $0 [-m mailboxdir] [-b backupdir]" >&2
         exit 1;;
  esac
done

# If MAILBOXDIR isn't set (or is null), then use default value
# Assume no backup desired
MAILBOXDIR=${MAILBOXDIR:="/volume1/homes/*/.Maildir"}
MAKEBACKUP=0;
MAILSERVER="/var/packages/MailServer/target"
MAILPERLLIB="${MAILSERVER}/lib/perl5" 
DBPATH="/var/spool/MailScanner/spamassassin"

# if the mailbox pattern wasn't specified, then error out
if [ -z "$MAILBOXDIR" ]; then
  echo "FATAL: The mailbox directory path pattern (-m) must be specified" >&2
  exit 1
fi

# figure out if a backup is desired and can be created
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
  MAKEBACKUP=1; 
fi

scan_mail () {
  echo "Mailbox path pattern: \"${MAILBOXDIR}\""

  echo "Scanning Spam folder(s)"
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --no-sync \
        --spam "${MAILBOXDIR}/.Junk/{new,cur}"

  echo "Scanning Ham folder(s)"
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --no-sync \
        --ham "${MAILBOXDIR}/{new,cur}"

  # Need to do the sync now as the Spam & Ham checks were performed no-sync for faster processing
  echo "Syncing SpamAssassin DB"
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --sync

  # Forgetting requires read/write access to the DB and so cannot be called w/ no-sync
  echo "Scanning Retrain folder(s)"
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --forget "${MAILBOXDIR}/.Retrain/{new,cur}"
}

dump_status () {
  echo "Current Status"
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --dump magic
}

backup_spamdb () {
  if [ $MAKEBACKUP -lt 1 ]; then
    return
  fi

  echo "Backing up SpamAssassin DB"
  perl -T -Mlib="${MAILPERLLIB}" "${MAILSERVER}/bin/sa-learn" \
        --username=postfix \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --backup > "${BACKUPDIR}/spamassassin.backup"
}

echo "==== Scan Start: $(date) ===="
scan_mail 
dump_status
backup_spamdb

# Make sure set ownership back to the default so that
# the MailScanner service can access the database
chown postfix:root "${DBPATH}"/bayes_*
echo "==== Scan Complete: $(date) ===="

exit 0
