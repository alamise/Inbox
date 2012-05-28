#!/bin/bash
ftp -inv ftp.inbox.tf << EOF
user inbox $1
cd www

bye
EOF 
