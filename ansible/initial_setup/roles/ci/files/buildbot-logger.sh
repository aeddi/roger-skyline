#!/bin/bash
tail -n 0 -f /home/buildbot/ci/master/twistd.log | sed -u -r 's/^(.*)\[-\] (.*)$/\2/' |  logger -t "buildbot-twistd[-]" -p local7.info
