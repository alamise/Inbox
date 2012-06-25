#!/bin/bash
lftp ftp://inbox@ftp.inbox.tf -e "mirror -e -R . / ;chmod -R 0777 /; quit"

