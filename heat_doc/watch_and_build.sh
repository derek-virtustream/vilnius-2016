#!/bin/bash
fswatch-run -e demo_stuff.tar.gz -e site -r ./ ./upload_to_s3.sh
