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

## Script Scheduling

## Caveats
This solution helps to improve upon the default spam-filtering capabilities with the Synology MailServer app. However, it takes exposure to a large body of mail (both Spam and Ham) for it to truly become effective. For smaller setups, this may take a longer period of time to accumulate enough datapoints to markedly improve the spam detection capabilities. 
