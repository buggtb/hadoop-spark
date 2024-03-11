#!/bin/bash

echo "Starting docker, this will take around 30 seconds"

#echo "Creating user $USER with id $USER_ID"
#useradd --uid $USER_ID --create-home $USER

if [ -z ${AWS_ACCESS_KEY_ID+x} ] || [ -z ${AWS_SECRET_ACCESS_KEY+x} ] ; then
  echo 
else 
  HDFS_SITE="
    <configuration>
      <property>
        <name>fs.s3a.access.key</name>
        <value>$AWS_ACCESS_KEY_ID</value>
      </property>
      <property>
        <name>fs.s3a.secret.key</name>
        <value>$AWS_SECRET_ACCESS_KEY</value>
      </property>
    </configuration>  
  "
  echo "$HDFS_SITE" > $HADOOP_CONF_DIR/hdfs-site.xml
fi

 #su $USER << EOF
if [ ! -d "/tmp/hive/data/hive/metastore_db" ]; then
  echo "Setting up metastore"
  cd /tmp/hive/data/hive
  $HIVE_HOME/bin/schematool -dbType derby -initSchema 
  cd
fi

echo "Launching spark"
$SPARK_HOME/sbin/start-master.sh
sleep 30
HOSTNAME=$(hostname)
$SPARK_HOME/sbin/start-worker.sh spark://$HOSTNAME:7077

echo "Launching Thrift"
$HIVE_HOME/hcatalog/sbin/hcat_server.sh start 
$SPARK_HOME/sbin/start-thriftserver.sh --master "spark://$HOSTNAME:7077" --conf "spark.sql.shuffle.partitions=2" --conf "spark.executor.cores=2" --conf "spark.driver.cores=2" --conf "spark.cores.max=2" --conf "spark.dynamicAllocation.maxExecutors=2"
sleep 20
#EOF

