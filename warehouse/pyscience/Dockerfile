# hivetech/pyscience image
# An ubuntu 12.04 LTS box with most common python packages for science installed
# VERSION 0.0.1

# Administration
FROM hivetech/base
MAINTAINER Xavier Bruhiere, xavier.bruhiere@gmail.com

# Install python2.7 and pip
/build/python.sh

# Requirements
RUN apt-get update && \
  apt-get install -y --no-install-recommends wget r-base g++ make libfreetype6-dev \
  libpng-dev libopenblas-dev liblapack-dev gfortran ipython && \
  pip install --upgrade pep8 nose cython patsy

RUN pip install -e git+https://github.com/numpy/numpy.git@master#egg=numpy && \
  pip install -e git+https://github.com/pydata/pandas.git@master#egg=pandas

RUN pip install -e git+https://github.com/scipy/scipy.git@master#egg=scipy && \
  pip install -e git+https://github.com/scikit-learn/scikit-learn.git@master#egg=sklearn

# Cleaning
/build/clean.sh

CMD ["ipython"]
# ipython notebook port
EXPOSE 8888
