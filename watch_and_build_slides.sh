#!/bin/bash
fswatch-run -e demo_stuff.tar.gz -e slides -r ./ ./upload_slides_to_s3.sh
