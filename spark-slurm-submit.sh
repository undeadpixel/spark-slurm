#!/bin/bash -l

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${SCRIPT_DIR}/slurm/_env.sh

print_help() {
cat << EOM
  spark-slurm-submit.sh NAME [other-spark-submit options and args]
EOM
  exit
}

if [ $# -lt 1 ]; then
  print_help
  exit
fi

NAME=$1; shift

CONFIG_PATH="${PREFIX_CONFIG_PATH}/${NAME}"
if [ ! -d ${CONFIG_PATH} ]; then
  echo "Server doesn't exist."
  exit
fi

CONDA_ENV=`cat ${CONFIG_PATH}/conda_env`
MASTER=`cat ${CONFIG_PATH}/master_host`
CPUS=`cat ${CONFIG_PATH}/worker_cpus`
MEM=`cat ${CONFIG_PATH}/worker_mem`

conda activate ${CONDA_ENV}
trap "conda deactivate" EXIT

MEM_WORKER=$(mem_worker $MEM)

spark-submit --master spark://$MASTER --conf spark.ui.showConsoleProgress=true \
--executor-cores=${CPUS} --executor-memory=${MEM_WORKER}g \
$@