#!/bin/bash

#python2 --version
#python2 -c 'import tensorflow as tf; print(tf.__version__)'

python --version
python -c 'import tensorflow as tf; print(tf.__version__)'

#python3 --version
#python3 -c 'import tensorflow as tf; print(tf.__version__)'

echo ===========================================================
pip list tensorflow | grep tensor
echo ===========================================================
conda list | grep tensor