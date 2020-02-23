#!/bin/bash

# Install python3
echo "[TASK 1] install python3"
sudo yum install -y centos-release-scl
sudo yum install -y rh-python36
echo "scl enable rh-python36 bash" 
scl enable rh-python36 bash
python --version
echo "[TASK 1] Done"
