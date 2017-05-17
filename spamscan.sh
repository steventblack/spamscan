#!/bin/sh

date
echo "Scanning Spam folder(s)"
perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --spam /volume1/homes/@LH-BLANCMANGE.SPRINGSURPRISE.COM/61/*/.Maildir/.Junk/{new,cur}/

echo "Scanning Ham folder(s)"
#perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --ham /volume1/homes/@LH-BLANCMANGE.SPRINGSURPRISE.COM/61/*/.Maildir/{new,cur}/
perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --ham /volume1/homes/@LH-BLANCMANGE.SPRINGSURPRISE.COM/61/steven-1000001/.Maildir/{new,cur}/

echo "Scanning Retrain folder(s)"
perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --spam /volume1/homes/@LH-BLANCMANGE.SPRINGSURPRISE.COM/61/*/.Maildir/.Retrain/{new,cur}/

echo "Updating SpamAssassin DB"                                                                                                                                                                                                                                      
perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --sync

echo "Current Status"
perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --dump magic

echo "Backing up SpamAssassin DB"
perl -T -Mlib=/var/packages/MailServer/target/lib/perl5/vendor_perl,/var/packages/MailServer/target/lib/perl5/core_perl /var/packages/MailServer/target/bin/sa-learn --siteconfigpath /var/packages/MailServer/target/etc/spamassassin --dbpath /var/spool/MailScanner/spamassassin/ --backup > /volume1/Archives/spamassassin.backup
date

