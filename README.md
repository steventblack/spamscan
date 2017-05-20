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

## SpamAssassin Configuration

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

## Scanning Options
`-m mailboxdir`

This option specifies the path pattern of the mailbox directories to be scanned. Note that it is intended to be a _pattern_ and not a single directory path, so the argument **must** be enclosed in double quotes in order to prevent premature expansion of the pattern expression. The actual pattern may vary depending on how the user accounts are setup on the Synology device. For local users, the default pattern of `"/volume1/homes/*/.Maildir"` should suffice. For users setup under LDAP, a pattern similar to `"/volume1/homes/@LH-SERVERNAME.EXAMPLE.COM/61/*/.Maildir"` would be required. 

`-b backupdir`

This option specifies the directory where a backup of the SpamAssassin database may be written. If not specified, then **no** backup is created. The directory must exist and have write permissions enabled. The file created will be named `spamassassin.backup`.

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

If options are specified for the script (`-m` or `-b`), then they must be included as part of the user defined script declaration.

The run time should be set to a period that enables the script to pick up new patterns frequently. However, the period should be longer than the scan time in order to prevent processes from "piling up". (e.g. If it takes an hour to complete the scan, then it should repeat no sooner than every 2 hours in order to prevent multiple scans from running concurrently.) It is not strictly necessary to have the run details sent via email, but enabling it may help if there's a need to troubleshoot.

## Caveats
This solution helps to improve upon the default spam-filtering capabilities with the Synology MailServer app. However, it takes exposure to a large body of mail (both Spam and Ham) for it to truly become effective. For smaller setups, this may take a longer period of time to accumulate enough datapoints to markedly improve the spam detection capabilities. 
