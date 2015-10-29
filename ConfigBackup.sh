#!/bin/bash
################################################################################
#                                Configuration                                 #
################################################################################

BASEDIR="/tftpboot"
FILTER="*.cfg"
GIT_ADD_ALL=false
GIT_DELETE=false

################################################################################
#                             Autoconf & Prepare                               #
################################################################################

GIT=`which git`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #"Bad MC syntax higlight
STARTDIR=`pwd`
CDATE=""
CUSER=""

################################################################################
#                            Procedures & Fuctions                             #
################################################################################

function git_commit() {
    if [[ $# < 1 ]]; then
        MESSAGE=`date +"%F %T"`
    else
        MESSAGE="$1"
    fi
    if [[ $# < 2 ]]; then
        AUTHOR="root"
        NAME=root
        EMAIL=root
    else
        AUTHOR=$2
    fi

    ROW=`grep -m 1  "^$AUTHOR" $DIR/users.txt`
    if [[ "$ROW" == "" ]]; then
        AUTHOR="$AUTHOR <$AUTHOR@backup.local>"
    else
        NAME=`echo $ROW | awk -F: '{print $2}' | xargs`
        EMAIL=`echo $ROW | awk -F: '{print $3}' | xargs`
        AUTHOR="$NAME <$EMAIL>"
    fi

    if [[ $EMAIL != "" ]]; then
        echo "Sending email to $AUTHOR about the config changes"
        mail -s "$MESSAGE" "$EMAIL" <<EOF
Dear $NAME,
    Your configuration changes have been backed up.

    $MESSAGE
EOF
    fi

    $GIT commit -m "$MESSAGE" --author "$AUTHOR" > /dev/null
}

function get_config_date() {
    if [[ $# < 1 ]]; then
        return
    fi
    LINE=`grep -m 1 "! Last configuration change at"  $1 | awk '{print $6" "$7" "$8" "$9" "$10" "$11}'`
    CDATE=`date --date="$LINE" +"%F %T"`
}

function get_config_user() {
    if [[ $# < 1 ]]; then
        return
    fi
    CUSER=`grep -m 1 "! Last configuration change at"  $1 | awk '{print $13}'`
}

################################################################################
#                             Base Program Start                               #
################################################################################

cd $BASEDIR

STATUS=`$GIT status > /dev/null 2>&1 ; echo $?`
if [[ $STATUS > 0 ]]; then
    STATUS=`$GIT init > /dev/null 2>&1; echo $?`
    if [[ $STATUS > 0 ]];then
        echo "Could not initialize GIT repository in $BASEDIR"
        exit 1
    fi
fi

if [ ! -f $BASEDIR/.gitignore ]; then
    echo "Missing .gitignore file, creating it..."
    echo "*.bin" > $BASEDIR/.gitignore
    $GIT add .gitignore
    git_commit "Adding .gitignore to the repository"
fi

if [ ! -f $BASEDIR/README.md ]; then
    echo "Missing README file, creating it..."
    echo "# Cisco backup files" > $BASEDIR/README.md
    $GIT add README.md
    git_commit "Adding README to the repository"
fi

STATUS=`$GIT status -s .gitignore | grep "^??" > /dev/null ; echo $?`
if [[ $STATUS = 0 ]]; then
    echo "Missing .gitignore from GIT, adding it..."
    $GIT add .gitignore
    git_commit "Adding .gitignore to the repository"
fi
STATUS=`$GIT status -s .gitignore | grep "^ M" > /dev/null ; echo $?`
if [[ $STATUS = 0 ]]; then
    echo "Updated .gitignore file, committing it..."
    $GIT add .gitignore
    git_commit "Updating .gitignore"
fi

STATUS=`$GIT status -s README.md | grep "^??" > /dev/null ; echo $?`
if [[ $STATUS = 0 ]]; then
    echo "Missing README from GIT, adding it..."
    $GIT add README.md
    git_commit "Adding README to the repository"
fi
STATUS=`$GIT status -s README.md | grep "^ M" > /dev/null ; echo $?`
if [[ $STATUS = 0 ]]; then
    echo "Updated README file, committing it..."
    $GIT add README.md
    git_commit "Updating README"
fi


################################################################################
#                             Processing config files                          #
################################################################################

for FILE in $FILTER ; do
    STATUS=`$GIT status -s $FILE | awk '{print $1}'`
    case $STATUS in
        ??)
            echo "Adding new file to backup repository: $FILE"
            $GIT add $FILE
            get_config_date $FILE
            get_config_user $FILE
            git_commit "NEW $FILE @ $CDATE" $CUSER
            ;;
        M)
            echo "Updating configuration file: $FILE"
            $GIT add $FILE
            get_config_date $FILE
            get_config_user $FILE
            git_commit "UPDATE $FILE @ $CDATE" $CUSER
            ;;

    esac
done

if [[ $GIT_ADD_ALL == true ]]; then
    if [[ $GIT_DELETE == true ]]; then
        STATUS=`git status -s | grep -e "^[? ][?MD]" > /dev/null ; echo $?`
    else
        STATUS=`git status -s | grep -e "^[? ][?M]" > /dev/null ; echo $?`
    fi
    if [[ $STATUS = 0 ]]; then
        $GIT add --all
        git_commit "`git status -s`"
    fi
fi

STATUS=`git remote update > /dev/null && git status | grep push > /dev/null ; echo $?`
if [[ $STATUS = 0 ]]; then
    echo "Configured REMOTE is not up-to-date, doing git push..."
    $GIT push > /dev/null
fi


################################################################################
#                                 Ending & cleanup                             #
################################################################################
cd $STARTDIR
