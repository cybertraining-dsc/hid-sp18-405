# Hadoop 2.9.0 cluster on Docker with Python Map-Reduce through Hadoop-streaming
#
# Application: sentiment analysis on movie review (Polarity 2.0 data)
#
# This Dockerfile creates pseudo distributed cluster
# 
# docker build  -t minchen57/hadoop-docker-python-sentiment-pseudo:latest .
#
# Modified from sequenceiq/hadoop-docker <https://github.com/sequenceiq/hadoop-docker>


FROM sequenceiq/pam:centos-6.5

MAINTAINER Min Chen

USER root

# install dev tools

RUN yum clean all \
    && rpm --rebuilddb \
    && yum install -y yum-plugin-ovl \
    && yum install -y curl which tar sudo openssh-server openssh-clients rsync \
    && yum update -y libselinux \
    && yum update -y nss curl libcurl tar gzip


# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


# java 8
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jdk-8u172-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie' && \
	rpm -i jdk-8u172-linux-x64.rpm && \
	rm jdk-8u172-linux-x64.rpm

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# hadoop
RUN curl -s http://mirrors.ocf.berkeley.edu/apache/hadoop/common/hadoop-2.9.0/hadoop-2.9.0.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hadoop-2.9.0 hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop


RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD conf/core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD conf/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD conf/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD conf/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

ADD conf/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

ADD conf/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

RUN service sshd start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
RUN service sshd start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

# Install Python
RUN yum install -y  gcc gcc-c++ make git patch openssl-devel zlib-devel readline-devel sqlite-devel bzip2-devel

RUN yum install -q -y net-tools

RUN git clone git://github.com/yyuu/pyenv.git .pyenv
#RUN git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

ENV HOME  /
ENV PYENV_ROOT /.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN pyenv install 3.6.2
RUN pyenv global 3.6.2
RUN python -m ensurepip
RUN pip install --upgrade pip
RUN pip install six
#RUN pip install nltk
#RUN python -m nltk.downloader stopwords
#RUN python -m nltk.downloader wordnet

# Copy the python scripts and download data
RUN mkdir -p /cloudmesh/python/data
#COPY python/data /cloudmesh/python/data
COPY python/*py /cloudmesh/python/
COPY python/*sh /cloudmesh/python/
RUN chmod +x /cloudmesh/python/*.py /cloudmesh/python/*.sh
RUN curl -s http://www.cs.cornell.edu/people/pabo/movie-review-data/review_polarity.tar.gz | tar -xz -C /cloudmesh/python/data
RUN mv /cloudmesh/python/split_data.sh /cloudmesh/python/data/split_data.sh

COPY python/startup.sh /etc/startup.sh
RUN chmod +x /etc/startup.sh

#CMD ["/etc/bootstrap.sh", "-d"]
CMD ["/etc/startup.sh", "-bash"]


# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
