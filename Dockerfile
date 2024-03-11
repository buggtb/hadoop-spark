FROM openjdk:8-jdk-bullseye
MAINTAINER Furcy Pin

# Install sbt
RUN apt update
#RUN apt -y install openjdk-21-jdk
ENV SBT_VERSION 0.13.15
RUN apt-get install apt-transport-https python3-pip curl gnupg -yqq && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list &&\
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list &&\
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import && \
    chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg && \
    apt-get update && \
    apt-get install sbt

# Install Hadoop
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/conf
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL \
  "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    | gunzip \
    | tar -x -C /opt/ \
  && rm -rf $HADOOP_HOME/share/doc \
  && chown -R root:root $HADOOP_HOME \
  && mkdir -p $HADOOP_HOME/logs \
  && mkdir -p $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_HOME/logs 


# Install Hive
ENV HIVE_VERSION=3.1.3
ENV HIVE_HOME=/opt/apache-hive-$HIVE_VERSION-bin
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH $PATH:$HIVE_HOME/bin
RUN curl -sL \
  "https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz" \
    | gunzip \
    | tar -x -C /opt/ \
  && chown -R root:root $HIVE_HOME \
  && mkdir -p $HIVE_HOME/hcatalog/var/log \
  && mkdir -p $HIVE_HOME/var/log \
  && mkdir -p /tmp/hive/data/hive/ \
  && mkdir -p $HIVE_CONF_DIR \
  && chmod 777 $HIVE_HOME/hcatalog/var/log \
  && chmod 777 $HIVE_HOME/var/log 

RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/aws-java-sdk-1.7.4.jar $HIVE_HOME/lib/. 
RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/hadoop-aws-2.7.3.jar $HIVE_HOME/lib/. 

# Install Spark
ENV SPARK_VERSION=3.5.1
ENV SPARK_HOME=/opt/spark-$SPARK_VERSION-bin-hadoop3
ENV SPARK_CONF_DIR=$SPARK_HOME/conf
ENV PATH $PATH:$SPARK_HOME/bin
RUN curl -sL \
  "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.tgz" \
    | gunzip \
    | tar -x -C /opt/ \
  && chown -R root:root $SPARK_HOME \
  && mkdir -p /data/spark/ \
  && mkdir -p $SPARK_HOME/logs \
  && mkdir -p $SPARK_CONF_DIR \
  && chmod 777 $SPARK_HOME/logs \
  && mkdir -p $SPARK_HOME/work \
  && chmod 777 $SPARK_HOME/logs


# Install Readline Wrapper
RUN apt update && apt-get install -y rlwrap \
 && rm -rf /var/lib/apt/lists/*

RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/aws-java-sdk-1.7.4.jar $SPARK_HOME/jars/. 
RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/hadoop-aws-2.7.3.jar $SPARK_HOME/jars/. 
RUN pip3 install faker
RUN chmod -R 777 /tmp/hive/
RUN chmod -R 777 /opt/spark-3.5.1-bin-hadoop3/work
# Configure
ADD files/hive-site.xml $HIVE_CONF_DIR/
ADD files/hive-site.xml $SPARK_CONF_DIR/
ADD files/start.sh /
ADD files/init.sh /
ADD files/beeline.sh /

EXPOSE 22
EXPOSE 4040
EXPOSE 9083
EXPOSE 10000

ENTRYPOINT ["/beeline.sh"]



