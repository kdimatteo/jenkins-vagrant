#!/bin/bash

function checkjenkins {
  S=`curl -f --silent http://localhost:6060/api/json | grep -Po 'mode'`
  if [[ $S ]]; then
    return 0
  else
    echo "waiting for Jekins..."
    sleep 2
    checkjenkins
  fi  
}



if [ ! -f /usr/bin/git ]; 
then
  echo "-------- PROVISIONING GIT ---------------"
  echo "---------------------------------------------"
  apt-get update
  #apt-get -y install git
  #http://unix.stackexchange.com/questions/33617/how-can-i-update-to-a-newer-version-of-git-using-apt-get
  apt-get -y install python-software-properties software-properties-common
  add-apt-repository ppa:git-core/ppa -y
  apt-get update
  apt-get -y install git
  git --version

else
  echo "CHECK - Git already installed"
fi


if [ ! -f /usr/bin/node ];
then
  echo "------ PROVISIONING NODE ---------"
  apt-get -y install nodejs
  apt-get -y install npm

  echo "Fix Node JS naming issue with a symlink"
  sudo ln -s /usr/bin/nodejs /usr/bin/node

else
  echo "CHECK - nodeJS already installed"
fi


if [ ! -f /usr/lib/jvm/java-7-oracle/bin/java ]; 
then
  echo "-------- PROVISIONING JAVA ------------"
  echo "---------------------------------------"

  ## Make java install non-interactive
  ## See http://askubuntu.com/questions/190582/installing-java-automatically-with-silent-option
  echo debconf shared/accepted-oracle-license-v1-1 select true | \
    debconf-set-selections
  echo debconf shared/accepted-oracle-license-v1-1 seen true | \
    debconf-set-selections

  ## Install java 1.7
  ## See http://www.webupd8.org/2012/06/how-to-install-oracle-java-7-in-debian.html
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
  echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
  apt-get update
  apt-get -y install oracle-java7-installer
else
  echo "CHECK - Java already installed"
fi

if [ ! -f /etc/init.d/jenkins ]; 
then
  echo "-------- PROVISIONING JENKINS ------------"
  echo "------------------------------------------"


  ## Install Jenkins
  #
  # URL: http://localhost:6060
  # Home: /var/lib/jenkins
  # Start/Stop: /etc/init.d/jenkins
  # Config: /etc/default/jenkins
  # Jenkins log: /var/log/jenkins/jenkins.log
  wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
  sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
  apt-get update
  apt-get -y install jenkins

  # Move Jenkins to port 6060
  sed -i 's/8080/6060/g' /etc/default/jenkins
  /etc/init.d/jenkins restart

  echo "Waiting for Jenkins to boot (this may take a moment) ..."
  checkjenkins

  #download jenkins CLI
  wget http://localhost:6060/jnlpJars/jenkins-cli.jar
  curl  -L http://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- http://localhost:6060/updateCenter/byId/default/postBack
  
  echo "Update plugins list..."
  /etc/init.d/jenkins restart
  checkjenkins

  echo "Installing plugins..."
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin git
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin git-client
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin credentials
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin multiple-scms
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin github-oauth
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin conditional-buildstep
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin greenballs
  java -jar jenkins-cli.jar -s http://localhost:6060/ install-plugin embeddable-build-status

  echo "restart jenkins..."
  /etc/init.d/jenkins restart

else
  echo "CHECK - Jenkins already installed"
fi


echo "-------- PROVISIONING DONE ------------"
echo "-- Jenkins: http://localhost:6060      "
echo "---------------------------------------"


