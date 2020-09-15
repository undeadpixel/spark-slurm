#!/bin/bash -l
#SBATCH --time=1-00:00:00

source ${SCRIPT_DIR}/slurm/_env.sh

NAME=$1
shift
ID=$1
shift
CPUS=$1
shift
MEM=$1

TMP_DIR="/tmp/spark.slave.${NAME}.${ID}"
mkdir -p ${TMP_DIR}

CONFIG_PATH="${PREFIX_CONFIG_PATH}/${NAME}"
CONDA_ENV=`cat ${CONFIG_PATH}/conda_env`
MASTER=`cat ${CONFIG_PATH}/master_host`

# source specifics for each configuration
ENV_CONFIG_FILE_PATH="${PREFIX_ENV_PATH}/${NAME}.sh"
if [ -f ${ENV_CONFIG_FILE_PATH} ]; then
  source ${ENV_CONFIG_FILE_PATH}
fi


MEM_WORKER=$(mem_worker $MEM)

conda activate $CONDA_ENV
trap "conda deactivate" EXIT

spark-class org.apache.spark.deploy.worker.Worker -c ${CPUS} -m ${MEM_WORKER}g -d ${TMP_DIR} spark://${MASTER}
