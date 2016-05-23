#!/bin/bash
. ../keystonerc_demo_160
mkdocs build --clean
tar czvf demo_stuff.tar.gz -C site/media salt pillar
swift upload saltstuff demo_stuff.tar.gz
swift post -r '.r:*' saltstuff
swift post -m 'web-listings: true' saltstuff
s3cmd put demo_stuff.tar.gz  s3://devopspro-heat/
s3cmd -P -r -f sync  site/* s3://devops-pro-2016.armyofevilrobots.com/
