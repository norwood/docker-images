#!/bin/bash

KAFKA_CFG_FILE="/etc/kafka/server.properties"

: ${KAFKA_BROKER_ID:=0}
: ${KAFKA_PORT:=9092}
: ${KAFKA_NUM_NETWORK_THREADS:=3}
: ${KAFKA_NUM_IO_THREADS:=8}
: ${KAFKA_SOCKET_SEND_BUFFER_BYTES:=102400}
: ${KAFKA_SOCKET_RECEIVE_BUFFER_BYTES:=102400}
: ${KAFKA_SOCKET_REQUEST_MAX_BYTES:=104857600}
: ${KAFKA_LOG_DIRS:=/var/lib/kafka}
: ${KAFKA_NUM_PARTITIONS:=1}
: ${KAFKA_NUM_RECOVERY_THREADS_PER_DATA_DIR:=1}
: ${KAFKA_LOG_RETENTION_HOURS:=168}
: ${KAFKA_LOG_SEGMENT_BYTES:=1073741824}
: ${KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS:=300000}
: ${KAFKA_LOG_CLEANER_ENABLE:=true}
: ${KAFKA_ZOOKEEPER_CONNECT:=$ZOOKEEPER_PORT_2181_TCP_ADDR:$ZOOKEEPER_PORT_2181_TCP_PORT}
: ${KAFKA_ZOOKEEPER_CONNECTION_TIMEOUT_MS:=6000}
: ${KAFKA_AUTO_CREATE_TOPICS_ENABLE:=true}
: ${KAFKA_DELETE_TOPIC_ENABLE:=true}

export KAFKA_BROKER_ID
export KAFKA_PORT
export KAFKA_NUM_NETWORK_THREADS
export KAFKA_NUM_IO_THREADS
export KAFKA_SOCKET_SEND_BUFFER_BYTES
export KAFKA_SOCKET_RECEIVE_BUFFER_BYTES
export KAFKA_SOCKET_REQUEST_MAX_BYTES
export KAFKA_LOG_DIRS
export KAFKA_NUM_PARTITIONS
export KAFKA_NUM_RECOVERY_THREADS_PER_DATA_DIR
export KAFKA_LOG_RETENTION_HOURS
export KAFKA_LOG_SEGMENT_BYTES
export KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS
export KAFKA_LOG_CLEANER_ENABLE
export KAFKA_ZOOKEEPER_CONNECT
export KAFKA_ZOOKEEPER_CONNECTION_TIMEOUT_MS
export KAFKA_AUTO_CREATE_TOPICS_ENABLE
export KAFKA_DELETE_TOPIC_ENABLE

TOTAL_MEMORY=`grep MemTotal /proc/meminfo | awk '{print $2}'`
echo "Container was launched with ${TOTAL_MEMORY}k of memory"

if [ -z ${KAFKA_HEAP_OPTS+x} ]; then
  HEAP_SIZE=`awk "BEGIN { rounded = sprintf(\"%.0f\", ${TOTAL_MEMORY} * 0.80); print rounded }"`
  export KAFKA_HEAP_OPTS="-Xmx${HEAP_SIZE}K"
  echo "Set KAFKA_HEAP_OPTS to ${KAFKA_HEAP_OPTS}"
fi

# Download the config file, if given a URL
if [ ! -z "$KAFKA_CFG_URL" ]; then
  echo "[kafka] Downloading Kafka config file from ${KAFKA_CFG_URL}"
  curl --location --silent --insecure --output ${KAFKA_CFG_FILE} ${KAFKA_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[kafka] Failed to download ${KAFKA_CFG_URL} exiting."
    exit 1
  fi
fi

echo '# Generated by kafka-docker.sh' > ${KAFKA_CFG_FILE}
for var in $(env | grep -v '^KAFKA_LOGS' | grep -v '^KAFKA_CFG_' | grep '^KAFKA_' | sort); do
  key=$(echo $var | sed -r 's/KAFKA_(.*)=.*/\1/g' | tr A-Z a-z | tr _ .)
  value=$(echo $var | sed -r 's/.*=(.*)/\1/g')
  echo "${key}=${value}" >> ${KAFKA_CFG_FILE}
done

export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/etc/kafka/log4j.properties"

exec /usr/bin/kafka-server-start ${KAFKA_CFG_FILE}
