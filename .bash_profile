#path variables
#export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
#export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
#letting sdkman handle java home for the time being
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_131.jdk/Contents/Home
export MAVEN_HOME=/Users/jacobkrieger/apache-maven-3.5.0/bin
export M2_HOME=/Users/jacobkrieger/.m2
export BREW_HOME=/usr/local/bin
export GRADLE_HOME=/opt/gradle/gradle-4.10.3/bin
export PATH=$BREW_HOME:$PATH:$JAVA_HOME:$MAVEN_HOME:$GRADLE_HOME

#global variables
export PRES="search1.liaison-intl.com:9200"
export QAES="10.10.12.225:9200"
export UNICAS_REPO=/Users/jacobkrieger/git_repos/unicas

#source files
. ~/.ticket_script
. ~/.bash_unicas

help() {
  echo All the help you\'re going to get:
  echo
  echo bash_profile:
  echo   rProfile         - Sources ~/.bash_profile
  echo   eProfile         - Opens the ~/.bash_profile in atom editor
  echo
  echo Building Unicas:
  echo   setDBProps       - Prompts for your eco internal hostname, sets 3 properties files
  echo   buildApplicant   - Efficiently builds the application to deploy applicant portal and management portal
  echo   revertProps      - Reverts properties files to branch HEAD.  Saves copies prior to reversion to root of unicas.
  echo
  echo Versioning:
  echo   mversion         - Replaces the version number of pom file in the current directory and attempts to update versions in all dependent projects.  Takes 1 parameter:  String version
  echo
  echo Housekeeping:
  echo   cleanUntrackedBranches - deletes git branches that do not have any remotely tracked counterpart.
}

#functions
vagrant-compose() {
  vagrant ssh -c "cd /vagrant ; docker-compose exec $*"
}

#git functions
#returns the current git branch in the working directory
parse_git_branch() {
#	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

#removes any branches from 'git branch' that do not have remote versions
internal_clean_untracked_branches() {
  #refresh the list of branches that have a remote head (ie. in origin/branchname)
  git fetch --prune
  #delete branches locally that do not have remote copies
  git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -D
}

cleanUntrackedBranches() {
  echo 'This command will delete local branches that are untracked by remote.'
  sleep 4
  echo 'If you have work on a branch that is not remote, you should cancel this command.'
  sleep 4
  echo 'Press CMD + C to cancel if you need to do this now.'
  sleep 4
  echo 'The script will run in 5 seconds.'
  sleep 5
  internal_clean_untracked_branches
}

export PS1="[\d][\t] \[\033[36m\]\$(parse_git_branch)\[\033[m\] \[\033[33m\]\w\[\033[m\] $"
#-----aliases

#list current directory with permissions group and filename
alias la='ls -lah'
alias eProfile='open -a atom ~/.bash_profile'
alias rProfile='source ~/.bash_profile'
alias atom='open -a atom'
#flush the DNS cache.
alias flushdns='sudo killall -HUP mDNSResponder'
alias mysql=/usr/local/mysql/bin/mysql
alias mysqladmin=/usr/local/mysql/bin/mysqladmin
#Ticket Aliases
alias echot=echoTickets
alias addt=addTicket
alias removet=removeTicket
alias savet=saveTickets

# git aliases
#delete branch (locally)
alias gdb='git branch -D'
#fetch and rebase
alias fr='git pull -r'

#docker shortcuts
alias dockerRmAll='docker rm $(docker ps -a -q)'
alias dockerStopAll='docker stop $(docker ps -a -q)'
alias dockerProxy='docker run -p 2375:2375 -v /var/run/docker.sock:/var/run/docker.sock -d -e PORT=2375 shipyard/docker-proxy'
alias dockerWeb='docker run -d -p 7070:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer'
alias rdocker='dockerStopAll;dockerRmAll;dockerProxy'
alias rimages='docker rmi $(docker images -q)'

#maven aliases
alias mi='mvn install'
alias mci='mvn clean install'
alias mcis='mvn clean install -DskipTests -Dmaven.test.skip=true'
alias mcisn='mvn clean install -DskipTests -DskipNG -Dmaven.test.skip=true'
alias mcin='mvn clean install -DskipNG'
alias mt='mvn test'

#kace aliases
alias stopkace='sudo /Library/Application\ Support/Quest/KACE/bin/AMPTools stop'
alias startkace='sudo /Library/Application\ Support/Quest/KACE/bin/AMPTools start'

function search() {
	directory=$2
	if [ -z $2 ]; then
		echo "\$2 is empty"
		directory="."
	fi
	echo "Recursive search in \"`pwd`\"  for \"$1\""
	grep -rn --color "$1" "$directory"
}

function memflush() {
	echo "commands [flush_all | quit]"
	telnet 10.10.12.168 11211
	#flush_all
	#quit
}

#maven functions
#mversion takes a single input which will be the version to update all poms that list the current directories pom as a dependency.
function mversion(){
    mvn org.codehaus.mojo:versions-maven-plugin:2.7:set -U -DnewVersion=$1 -DoldVersion='*' -DgenerateBackupPoms=false -DupdateMatchingVersions=false
}

function mcisall(){
   currentdir=`pwd`
   cd $UNICAS_REPO
   mvn clean install -DskipTests -DskipNG -Dmaven.test.skip=true -Pall $1 && mvn install -DskipTests -Dmaven.test.skip=true -f applicant-ui/pom.xml
   cd $currentdir
   afplay /System/Library/Sounds/purr.aiff
}

function mciall(){
   currentdir=`pwd`
   cd $UNICAS_REPO
   mvn clean install -DskipNG -Pall $1
   cd $currentdir
   afplay /System/Library/Sounds/purr.aiff
}

#ssh connections
alias sshelk_qa='ssh jacob@10.10.12.225'
alias sshelk_prod='ssh jacob@search1.liaison-intl.com'

#function to ssh into a given elk node
function sshelk() {
  if [ $# -ne 1 ]; then
    sshelk_qa
  elif [ "$1" == "qa" ]; then
    sshelk_qa
  elif [ "$1" == "prod" ]; then
    sshelk_prod
  fi
}
#alias scpelk='scp jacob@10.10.12.225'

function scp_from_qa() {
  scp jacob@10.10.12.225:$1 $2
}

function scp_to_qa() {
  scp $1 jacob@10.10.12.225:/home/jacob
}

function scp_from_prod() {
  scp jacob@search1.liaison-intl.com:$1 $2
}

function scp_to_prod() {
  scp $1 jacob@search1.liaison-intl.com:/home/jacob
}

function get() {
  echo "curl -XGET $1/$2"
  curl -XGET $1/$2 | python -m json.tool
}

function post() {
  #echo $3
  echo "curl -XPOST \"$1/$2\" -H \"Content-Type:application/json\" -d"''"$3"''
  curl -XPOST "$1/$2" -H "Content-Type:application/json" -d''"$3"''
}

function put() {
  echo $3
  json=cat
  echo "curl -XPOST $1/$2 -H \"Content-Type:application/json\" -d"''"$3"''
  curl -XPUT "$1/$2" -H "Content-Type:application/json" -d''"$3"''
}

function qaput() {
  put $QAES $1 "$2"
}

function qapost() {
  post $QAES $1 "$2"
}

function devput() {
  put $PRES $1 "$2"
}

function prodpost() {
  post $PRES $1 "$2"
}

function qaget() {
  get $QAES $1
}


#import tickets file.
loadTickets

help

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

##
# Your previous /Users/jacobkrieger/.bash_profile file was backed up as /Users/jacobkrieger/.bash_profile.macports-saved_2018-01-07_at_15:51:24
##

# MacPorts Installer addition on 2018-01-07_at_15:51:24: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jacobkrieger/Downloads/google-cloud-sdk/path.bash.inc' ]; then . '/Users/jacobkrieger/Downloads/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jacobkrieger/Downloads/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/jacobkrieger/Downloads/google-cloud-sdk/completion.bash.inc'; fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/jacobkrieger/.sdkman"
[[ -s "/Users/jacobkrieger/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/jacobkrieger/.sdkman/bin/sdkman-init.sh"
