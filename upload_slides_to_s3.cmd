#!/bin/bash
s3cmd -P -r -f sync  slides/* s3://devops-pro-2016.armyofevilrobots.com/slides/
