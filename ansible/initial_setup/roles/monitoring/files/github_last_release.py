#!/usr/bin/env python

import json
import urllib
import urllib2
import subprocess
from sys import stderr,stdout,argv

def main():
    # Github: GET /repos/:owner/:repo/releases
    # curl -H "Accept: application/json" "https://api.github.com/repos/maxhq/zabbix-backup/releases"
    REPOSITORY = 'zabbix-backup'
    OWNER = 'maxhq'
    API_REQ_URL = "https://api.github.com/repos/{}/{}/releases".format(OWNER, REPOSITORY)
    API_REQ_HDR = {"Accept" : "application/json" }
    API_REQ_DATA = None
    req_obj = urllib2.Request(API_REQ_URL, API_REQ_DATA, API_REQ_HDR)
    response = urllib2.urlopen(req_obj)
    if not response:
        stderr.write("{}: failed to release data\n".format(argv[0]))
        exit(1)
    ans_list = response.read()
    ans_list = json.loads(ans_list)
    url = None
    
    # Get the most recent release tarball.
    for o in ans_list:
        if type(o) is dict and "tarball_url" in o:
            url = o["tarball_url"]
            break
    
    if not url:
        stderr.write("{}: failed to fetch release tarball URL\n".format(argv[0]))
        exit(1)
    
    ans_list = None

    base_name = '{}-{}'.format(OWNER, REPOSITORY)
    version = url.split('/')[-1]
    open(base_name + '.version', 'w').write(version)
    filepath = base_name + '.tgz'
    urllib.urlretrieve(url, filepath)
    stdout.write(filepath + '\n')

if __name__ == '__main__':
    main()
