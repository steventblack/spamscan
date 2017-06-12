# spamscan

## Background
The main goal of this project is to improve the spam handling facilities available from the Synology MailServer application. While MailServer already makes use of the popular SpamAssassin tool, the user-interface doesn't provide access to some of the more advanced features available with SpamAssassin. This project enables the Bayesian filtering capabilities of SpamAssassin with the capacity to learn to identify both Spam and Ham (non-spam email). In addition, it provides a facility for retraining the filter should it accidentally misclassify an email.

## Requirements
This project requires some familiarity with the basic Unix system and tools. Additionally, access to the Synology admin interface is requried. This project _does_ involve access to the internals to your system. As such, there is always the risk of an accident or mistake leading to irrecoverable data loss. **Be mindful when logged onto your system -- especially when performing any action as root or admin.**

This project should be completed in 30-45 minutes.

This service requires the following skills:
* Editing files on a Unix system (e.g. `vi`, `nano`)
* A working mail server setup using the Synology MailServer app
* SSH access
* Standard Unix tools (`sudo`, `chown`, `chmod`, `mv`, `cd`, `ls`, `wget`, `cat`, etc.)
* Administration/root access to the Synology device

These instructions have been verified as working on a Synology DS1513+ running DSM 6.1.1-15101 Update 2. 

## Scanning Options

`-b backupdir`

This option specifies the directory where a backup of the SpamAssassin database may be written. If not specified, then **no** backup is created. The directory must exist and have write permissions enabled. The file created will be named `spamassassin.backup`.

`-h`

This option specifies a scan for ham (non-spam) email should be performed. The directory(s) to be scanned use the mailbox path pattern as specified by the `-m` option or the default mailbox path pattern if no other pattern supplied. In general, a directory of recent, pre-screened email messages should be referenced so that the Bayes system is able to learn effectively.

`-H hamdir`

The option specifies a scan for ham (non-spam) email should be performed. The directory to be scanned is specified with this option so the full path to the ham directory should be provided. In general, a directory of recent, pre-screened email messages should be referenced so that the Bayes system is able to learn effectively. If a path pattern is provided, it **must** be enclosed within double quotes in order to prevent premature pattern expansion.

`-i`

This option prints out basic information about the Bayes database. More information about the output can be found at the SpamAssassin site.

`-m mailboxdir`

This option specifies the path pattern of the mailbox directories to be scanned. Note that it is intended to be a _pattern_ and not a single directory path, so the argument **must** be enclosed in double quotes in order to prevent premature expansion of the pattern expression. The actual pattern may vary depending on how the user accounts are setup on the Synology device. For local users, the default pattern of `"/volume1/homes/*/.Maildir"` should suffice. For users setup under LDAP, a pattern similar to `"/volume1/homes/@LH-SERVERNAME.EXAMPLE.COM/61/*/.Maildir"` would be required. 

`-r`

This option specifies a scan for email that was misclassified in order to reset the learning associated with the message. Messages which are either incorrectly classified as ham **or** spam can be placed into the designated "Retrain" folder for processing. The directory(s) to be scanned use the mailbox path pattern as specified by the `-m` option or the default mailbox path pattern if no other pattern supplied. This option requires the directory to be named "Retrain".

`-R retraindir`

The option specifies a scan for retraining email should be performed. The full path of the directory to be scanned is specified with this option. If a path pattern is provided, it **must** be enclosed in double quotes in order to prevent premature expansion of the pattern expression.

`-s`

This option specifies a scan for spam email should be performed. The directory(s) to be scanned use the mailbox path pattern as specified by the `-m` option or the default mailbox path pattern if no other pattern supplied. In general, a directory of recent, pre-screened email messages should be referenced so that the Bayes system is able to learn effectively.

`-S spamdir`

The option specifies a scan for spam email should be performed. The full path of the directory to be scanned is specified with this option. In general, a directory of recent, pre-screened email messages that are known to contain only spam should be referenced so that the Bayes system is able to learn effectively. If a path pattern is provided, it **must** be enclosed within double quotes in order to prevent premature pattern expansion.

## Script Installation
1. SSH as the administrator to the Synology device
    * `ssh admin@synology.example.com`
1. Navigate to the appropriate directory
    * `cd /usr/local/bin`
1. Download the `spamscan.sh` script
    * `sudo wget -O spamscan.sh "https://raw.githubusercontent.com/steventblack/spamscan/master/spamscan.sh"`
1. Change the owner and permissions of the script
    * `sudo chown root:root spamscan.sh`
    * `sudo chmod +x spamscan.sh`
1. Verify the script works with the desired command line options
    * `sudo ./spamscan.sh -m <mailboxdir> -b <backupdir>`
    
It may take a lengthy period of time for the script to complete if there is a large amoount of email to process. On a DS1513+, it processes ~20,000 messages per hour. Please be patient and verify the script is able to fully execute.
    
## Script Scheduling
1. Log in as administrator to the Synology DSM (administration interface)
1. Open up the "Control Panel" app.
1. Select the "Task Scheduler" service.
1. Create a new Scheduled Task for a user-defined script.
1. For the "General" tab, fill in the fields as follows:
    * Task: `Spam Scn Update`
    * User: `root`
    * Enabled: (checked)
1. For the "Schedule" tab, fill in fields as follows:
    * Run on the following days: Daily
    * First run time: `00:00`
    * Frequency: Every 2 hour(s)
1. For the "Task Settings" tab, fill in the fields as follow:
    * Send run details by email: `<your email here>`
    * User defined script: `sudo /usr/local/bin/spamscan.sh`

If options are specified for the script (`-m` or `-b`), then they must be included as part of the user defined script declaration. It is also recommended that the output be captured in order to verify the system is working as expected. The script can use standard Unix output redirection in order to capture the output to a log file.

The run time should be set to a period that enables the script to pick up new patterns frequently. However, the period should be longer than the scan time in order to prevent processes from "piling up". (e.g. If it takes an hour to complete the scan, then it should repeat no sooner than every 2 hours in order to prevent multiple scans from running concurrently.) It is not strictly necessary to have the run details sent via email, but enabling it may help if there's a need to troubleshoot.

A full working example of a user defined script which captures the output to a log file is provided below. Note that the `-m` param _requires_ the double quotes surrounding it in order to prevent premature expansion of the pattern. The output is redirected to `/tmp/spamscan.log` and should capture both stdout as well as stderr output (`2>&1`).

`sudo /usr/local/bin/spamscan.sh -m "/volume1/homes/*/.Maildir" -b /volume1/Archives >> /tmp/spamscan.log 2>&1`

## SpamAssassin Configuration
In order to properly utilize the learning, some configuration changes need to be made to the configuration files of the MailServer package. In order to preserve the changes over system reboots, the change must be made in the "template" file. In addition, it is probably a good practice to review the configuration files after system upgrades or if the MailServer package has been upgraded in order to ensure the necessary changes are preserved.

1. SSH as the administrator to the Synology device
    * `ssh admin@synology.example.com`
1. Navigate to the appropriate directory
    * `cd /var/packages/MailServer/target/etc/template`
1. Open `mailscanner.template` for editing
    * `sudo vi mailscanner.template`
1. Update the following lines and save the file
    * `%org-name% = <organization>`
    * `Always Include SpamAssassin Report = yes`
    * `Multiple Headers = add`
    * `Place New Headers At Top Of Message = yes`
    * `Log Spam = yes`
    * `Log Non Spam = yes`
1. Log in as administrator to the Synology DSM (administration interface)
1. Open up the "Packages" app.
1. Select the "Mail Server" service.
1. Stop the Mail Server using the drop-down menu
1. Restart the Mail Server by selecting "Run" using the drop-down menu

Notes:

* The `%org-name%` has a number of restrictions so keeping it short & simple is best. There should be no spaces or punctuation except for a "-". To help improve the readability of the mail headers, it may be desired to start the name with a capital letter and end it with a trailing "-".  e.g. "ExampleCorp-", "MyHouse-", etc. 
* The `Always Include SpamAssassin Report` line ensures the results of the mail scanner are always included in the mail messages even if the message isn't classified as spam.
* The `Mutliple Header` and `Place New Headers At Top Of Message` lines should be be changed to ensure that the additional headers from the spam checker do not interfere with other spam control services (e.g. DKIM).
* The `Log Spam` and `Log Non Spam` lines result in (spam and ham) messages being logged. This output can get rather lengthy over time and may be disabled if the service seems to be performing normally and storage space is a concern.
* Stopping and restarting the Mail Server service is required to pickup the changes in the mailscanner.template configuration file. There may be additional steps required if dependent packages are installed (e.g. Mail Station).

## Usage
The script will search only selected email folders for training. If the directory paths are not explicitly provided, the names of the email folders must match exactly (including capitalization) or it will not be scanned.

- Ham: The primary inbox of the email directory is scanned for examples of _ham_
- Spam: An email folder named "**Junk**" is scanned for examples of _spam_
- Retraining: An email folder named "**Retrain**" is scanned if a message has been incorrectly tagged (as either spam or ham)

## Caveats
This solution helps to improve upon the default spam-filtering capabilities with the Synology MailServer app. However, it takes exposure to a large body of mail (both Spam and Ham) for it to truly become effective. For smaller setups, this may take a longer period of time to accumulate enough datapoints to markedly improve the spam detection capabilities. 
