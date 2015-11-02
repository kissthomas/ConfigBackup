# Cisco Backup repository manager

This script can track configuration files created by check_cisco_config_backup
or any other script that can collect cisco startup/running configuration.

The script parses the head of all configuration file to extract the
configuration time and the login name who configured it
based on the __Last configuration change__ row. the username can be looked
up from a small textfile "database".

## Usage

### Initial configuration

There are some variables you should check in configuration section of
ConfigBackup.sh:
1. BASEDIR="/tftpboot"

   This variable points to the directory where the configuration files are

2. FILTER="*.cfg"

   This variable is a mask used by the script to check ONLY the
   configuration files

3. GIT_ADD_ALL=false

   If you set this variable to true, ALL files will be added to the git
   repository (but not checked by the script for user/date fileds). This
   is good for versioning other kind of configuration files or anything
   else.

4. GIT_DELETE=false

   If you set this value to true, the script will check for deleted files
   and will delete them from the git repostiory too.

5. REMOVE_THESE=("clock-period" "AnotherstuffToRemove")

   You can specify keywords which you don't want to include in your backup.
   A good example is __ntp clock-period__ on Cisco, which can change every
   time you backup your configuration.


### User configuration

The script can generate correct git author (User Name <email@address.com>)
for each commit. To use this you should copy the __users.sample.txt__ to
__users.txt__. This file is a colon separated list where you should fill
all cisco logins with the appropirate name/email addresses.

### Git configuration

When you run the backup script first, it will automatically create a git
repository with a .gitignore and a README.md file. Both files will be added
to the repository.

> Notice: if you want to use special .gitignore or README.md you can
> create them before running the backup script. Files will be recognised by
> the script and will be added to the repository. The basic .gitignore file
> only exclide *.bin files (handy if you store cisco images on the TFTP server)

After the repository has been created, you can add a remote repository
which can be automatically pushed by the script:

```git
git remote add origin user@hostname:project/repo.git
git push --set-upstream origin master
```

### Cron configuration

The easiest way to run the script is to copy ConfigBackup_cron to your
cront.hourly directory. You should check out the configuration section of
the cron script too:

1. SCRIPT=/opt/ConfigBackup/ConfigBackup.sh

   This is the location of the backup script.

2. LOG=/var/log/ConfigBackup.log

   This is the location of the log file, where the cron script redirects its
   output.

### Logfile handling

There is a logrotate script which you can just drop in tu your logrotate.d
directory named ConfigBackup.logrotate
