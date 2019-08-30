#!/bin/bash -ex

echo "starting script..."
env | grep TRAVIS
gimme -l
gimme 1.12.9
# install a more recent Go than apt-get can supply
#curl https://dl.google.com/go/go1.12.9.linux-amd64.tar.gz -o go.tar.gz
#sudo tar -xvzf go.tar.gz -C /usr/local/
go version
go env

source /home/travis/.gimme/envs/*.env
#export GOROOT=/usr/local/go
#export PATH="$PATH:${GOROOT}/bin"

echo "installing ghr"
go get github.com/tcnksm/ghr
echo "ghr reported $?"

exit 1
