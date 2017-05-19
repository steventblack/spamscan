#!/bin/sh

#######################
# (C) 2017 Steven Black
#######################
#
# 2017-05-17 - 1.0.0 Initial checkin of working script
# 2017-05-17 - 1.1.0 Major cleanup; fix retrain to "forget"
# 2017-05-17 - 1.2.0 No-sync flag added for spam & ham checks
# 2017-05-18 - 1.3.0 Process command line args for mailboxdir and backupdir
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
    [?]) echo "Usage $0 -m mailboxdir [-b backupdir]" >&2
         exit 1;;
  esac
done

# if the mailbox pattern wasn't specified, then error out
if [ -z "$MAILBOXDIR" ]; then
  echo "The mailbox directory path pattern (-m) must be specified" >&2
  exit 1
fi

MAILSERVER="/var/packages/MailServer/target"
MAILPERLLIB="${MAILSERVER}/lib/perl5" 
DBPATH="/var/spool/MailScanner/spamassassin"

echo "==== Scan Start: $(date) ===="
echo "MAILBOXDIR: \"${MAILBOXDIR}\""

echo "Scanning Spam folder(s)"
perl -T -Mlib="${MAILPERLLIB}/vendor_perl,${MAILPERLLIB}/core_perl" "${MAILSERVER}/bin/sa-learn" \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --no-sync \
        --spam "${MAILBOXDIR}/.Junk/{new,cur}"

echo "Scanning Ham folder(s)"
perl -T -Mlib="${MAILPERLLIB}/vendor_perl,${MAILPERLLIB}/core_perl" "${MAILSERVER}/bin/sa-learn" \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --no-sync \
        --ham "${MAILBOXDIR}/{new,cur}"

# Need to do the sync now as the Spam & Ham checks were performed no-sync for faster processing
echo "Syncing SpamAssassin DB"
perl -T -Mlib="${MAILPERLLIB}/vendor_perl,${MAILPERLLIB}/core_perl" "${MAILSERVER}/bin/sa-learn" \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --sync

# Forgetting requires read/write access to the DB and so cannot be called w/ no-sync
echo "Scanning Retrain folder(s)"
perl -T -Mlib="${MAILPERLLIB}/vendor_perl,${MAILPERLLIB}/core_perl" "${MAILSERVER}/bin/sa-learn" \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --forget "${MAILBOXDIR}/.Retrain/{new,cur}"

echo "Current Status"
perl -T -Mlib="${MAILPERLLIB}/vendor_perl,${MAILPERLLIB}/core_perl" "${MAILSERVER}/bin/sa-learn" \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --dump magic

echo "Backing up SpamAssassin DB"
perl -T -Mlib="${MAILPERLLIB}/vendor_perl,${MAILPERLLIB}/core_perl" "${MAILSERVER}/bin/sa-learn" \
        --siteconfigpath "${MAILSERVER}/etc/spamassassin" \
        --dbpath "${DBPATH}" \
        --backup > /volume1/Archives/spamassassin.backup

echo "==== Scan Complete: $(date) ===="

exit 0
