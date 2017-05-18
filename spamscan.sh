#!/bin/sh

#######################
# (C) 2017 Steven Black
#######################
#
# 2017-05-17 - 1.0.0 Initial checkin of working script
# 2017-05-17 - 1.1.0 Major cleanup; fix retrain to "forget"
# 2017-05-17 - 1.2.0 No-sync flag added for spam & ham checks
#
#######################


# Check to ensure mailbox path has been specified
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 MAILBOXPATH" >&2
  exit 1
fi

# MAILBOXDIR *must* be wrapped in quotes when passed in to avoid premature globbing
MAILBOXDIR=$1 
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
