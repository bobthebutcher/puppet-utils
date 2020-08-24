#! /bin/bash

WORK_DIR="/tmp";
PUPPET_VERSION="6";

check_puppet_installed () {
  if [[ -f /opt/puppetlabs/bin/puppet ]]; then
    echo "Puppet is already installed.";
    exit 0;
  fi
}

get_release () {
  ######## REDHAT FAMILY ########
  if [[ -f /etc/redhat-release ]]; then
    package_manager="yum";
    os_family="el";
    echo "Redhat Family";
    if grep -q "CentOS" /etc/redhat-release; then
      echo "Centos Family";
      if grep -q "release 7" /etc/redhat-release; then
        os_version="7";
        echo "$os_family"-"$os_version" Family;
      fi
    fi
    puppet_release=puppet"$PUPPET_VERSION"-release-"$os_family"-"$os_version".noarch.rpm;
    repo_url=https://"$package_manager".puppet.com/puppet"$PUPPET_VERSION"/"$puppet_release";

  ######## DEBIAN FAMILY ########
  elif [[ -f /etc/lsb-release ]]; then
    if grep -q -E "(Cumulus|Debian|Ubuntu)" /etc/lsb-release; then
      package_manager="apt";
      echo "Debian Family"; 
      if grep -q "bionic" /etc/lsb-release; then
        echo "Ubuntu Family";
        os_family="bionic";
      elif grep -q "Cumulus" /etc/lsb-release; then
        echo "Cumulus Family";
        if grep -q "Cumulus Linux 3." /etc/lsb-release; then
          echo "Jessie Family";
          os_family="jessie";
        fi
      fi
    fi
    puppet_release=puppet"$PUPPET_VERSION"-release-"$os_family".deb;
    repo_url=https://"$package_manager".puppet.com/"$puppet_release";
  else
    echo "Unable to determine release";
    exit 1;
  fi
  echo $puppet_release;
  echo $repo_url;
}

main() {
  check_puppet_installed;
  get_release;

  curl -o "$WORK_DIR"/"$puppet_release" -O "$repo_url";

  # Install
  case $package_manager in
  "yum")
    sudo rpm -Uvh "$WORK_DIR"/"$puppet_release";
    sudo yum install -y puppet;
  ;;
  "apt")
    sudo dpkg -i "$WORK_DIR"/"$puppet_release";
    sudo apt update -y;
    sudo apt install -y puppet-agent;
  ;;
  *)
    echo "Unknown Package Manager";
    exit 1;
  ;;
  esac

  # Clean up
  rm "$WORK_DIR"/"$puppet_release";
  exit 0;
}

main;
