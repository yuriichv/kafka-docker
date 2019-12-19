#!/bin/sh 
set -e

ZK=zoo1
KAFKA_CLUSTER=(kafka1.cmx.ru:9092 kafka2.cmx.ru:9093 kafka3.cmx.ru:9094)
KAFKA=${KAFKA_CLUSTER[0]}
CLIENT=test-client
TOPIC=test03

echo -e "Тест создания топика. Replicaiton factor 3 потребует наличие в кластере 3х нод."
kafka-topics.sh --create --topic $TOPIC --replication-factor 3 --partitions 1 --zookeeper $ZK  
kafka-topics.sh --describe --topic $TOPIC --zookeeper $ZK  

echo -e "TEST topic creation 	=FINISHED \n"

#kafka-acls.sh  --authorizer-properties zookeeper.connect=$ZK  --topic $TOPIC --add  --allow-principal User:CN=$CLIENT --operation Describe --operation Read --operation Write  
#kafka-acls.sh  --authorizer-properties zookeeper.connect=$ZK  --group $CLIENT-consumer-group --add  --allow-principal User:CN=$CLIENT --operation Describe --operation Read  
#echo -e "TEST ACL creation   	=FINISHED \n"

echo -e "Тест записи. Также проверяем SSL, ACL.\n"
echo "Message: test" | kafka-console-producer.sh --producer.config $CLIENT.properties --broker-list $KAFKA --topic $TOPIC && \
  echo -e "\nTEST Producer Write	  =PASSED \n"

echo -e "Тест чтения по брокерам. Т.к. partition 1 то все ноды должны редиректить клиента на лидер. Если кластер не целостен, чтения не будет. Одновременно проверяется SSL, ACL (позитивные сценарии). \n"
for KAFKA in ${KAFKA_CLUSTER[@]}; do
  echo -e "reading from broker $KAFKA... "
  kafka-console-consumer.sh --consumer.config $CLIENT.properties --bootstrap-server $KAFKA --topic $TOPIC --group=$CLIENT-consumer-group --partition 0 --offset 0 --max-messages 1 
done && \
echo -e "TEST Consumer read	  =PASSED \n"

kafka-topics.sh --delete --topic $TOPIC --zookeeper $ZK  
