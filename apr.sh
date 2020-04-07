#!/bin/bash

echo "start install apr"

if [[ ${JAVA_HOME} == '' ]]; then
  echo "请先配置JAVA_HOME！"
  exit
fi

DIR=/opt/apr
mkdir ${DIR} -p

yum install expat-devel -y
yum install wget  -y
yum install gcc-c++  -y

URL_HOST=https://mirror.bit.edu.cn

APR=apr-1.7.0
APR_UTIL=apr-util-1.6.1
APR_ICONV=apr-iconv-1.2.2
APACHE_TOMCAT=apache-tomcat-9.0.33

if [[ ! -f ${DIR}/apr.tar.gz ]];then
    wget -O ${DIR}/apr.tar.gz ${URL_HOST}/apache//apr/${APR}.tar.gz
fi

if [[ ! -f ${DIR}/apr-util.tar.gz ]];then
    wget -O ${DIR}/apr-util.tar.gz ${URL_HOST}/apache//apr/${APR_UTIL}.tar.gz
fi

if [[ ! -f ${DIR}/apr-iconv.tar.gz ]];then
    wget -O ${DIR}/apr-iconv.tar.gz ${URL_HOST}/apache//apr/${APR_ICONV}.tar.gz
fi

if [[ ! -f ${DIR}/tomcat.tar.gz ]];then
    wget -O ${DIR}/tomcat.tar.gz ${URL_HOST}/apache/tomcat/tomcat-9/v9.0.33/bin/${APACHE_TOMCAT}.tar.gz
fi


if [[ ! -d ${DIR}/${APR} ]];then
    tar -zxf ${DIR}/apr.tar.gz
fi

if [[ ! -d ${DIR}/${APR_UTIL} ]];then
    tar -zxf ${DIR}/apr-util.tar.gz
fi

if [[ ! -d ${DIR}/${APR_ICONV} ]];then
    tar -zxf ${DIR}/apr-iconv.tar.gz
fi

if [[ ! -d ${DIR}/${APACHE_TOMCAT} ]];then
    tar -zxf ${DIR}/tomcat.tar.gz
fi


if [[ ! -d /usr/local/apr ]];then
  cd ${DIR}/${APR}
  ./configure --prefix=/usr/local/apr
  make
  make install
fi

if [[ ! -d /usr/local/apr-iconv ]];then
  cd ${DIR}/${APR_ICONV}
  ./configure --prefix=/usr/local/apr-iconv --with-apr=/usr/local/apr
  make
  make install
fi

if [[ ! -d /usr/local/apr-util ]];then
  cd ${DIR}/${APR_UTIL}
  ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr --with-apr-iconv=/usr/local/apr-iconv/bin/apriconv
  make
  make install
fi

tar -zxf ${DIR}/${APACHE_TOMCAT}/bin/tomcat-native.tar.gz
cd ${DIR}/${APACHE_TOMCAT}/bin/tomcat-native-*/native
./configure --with-apr=/usr/local/apr
make
make install

echo "apr install success"