#!/bin/bash
lftp ftp://inbox@ftp.inbox.tf -e "mirror -e -R . / ; quit"

