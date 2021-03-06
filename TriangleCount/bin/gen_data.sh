#!/bin/bash
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== preparing ${APP} data =========="

# paths check
${RM} -r ${INPUT_HDFS}

# generate data
START_TS=`get_start_ts`;
setup
#genOpt="small"
genOpt="large"
if [ $genOpt = "large" ];then
	${MKDIR} ${APP_DIR}
	${MKDIR} ${INPUT_HDFS}
	srcf=${DATASET_DIR}/web-Google.txt
	#srcf=${DATASET_DIR}/BigDataGeneratorSuite/Graph_datagen/AMR_gen_edge_24.txt
	START_TIME=`timestamp`
	${CPFROM} $srcf ${INPUT_HDFS}	
        for((i=1; i<${DATA_COPIES}; i++)); do
          ${HADOOP_HOME}/bin/hdfs dfs -appendToFile $srcf ${INPUT_HDFS}/web-Google.txt 2> /dev/null
        done
elif [ $genOpt = "small" ];then
	JAR="${DIR}/../common/target/Common-1.0.jar"
	CLASS="DataGen.src.main.scala.GraphDataGen"
	OPTION="${INOUT_SCHEME}${INPUT_HDFS} ${numV} ${NUM_OF_PARTITIONS} ${mu} ${sigma}"
	START_TIME=`timestamp`
    exec ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${APP_MASTER} ${YARN_OPT} ${SPARK_OPT}  $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/${APP}_gendata_${START_TS}.dat
res=$?;
else
	echo "error genOpt $genOpt"
	exit 0
fi

END_TIME=`timestamp`
SIZE=`${DU} -s ${INPUT_HDFS} | awk '{ print $1 }'`
get_config_fields >> ${BENCH_REPORT}
print_config  ${APP}-gen ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT};
teardown
exit 0


