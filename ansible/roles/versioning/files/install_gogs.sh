#!/bin/sh
export HOME2=/home/git
export GOROOT=$HOME2/go-linux-ppc64le-bootstrap;
export PATH=$PATH:$GOROOT/bin;
export GOPATH=$HOME2/goworkspace;
go get -u github.com/gogits/gogs && cd $GOPATH/src/github.com/gogits/gogs && go build
