#!/bin/bash
mkdir -p ./es2-dev-bkup
aws s3 sync s3://plasmaguard-es2-dev-bkup ./es2-dev-bkup
