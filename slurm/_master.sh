#!/bin/bash -l

#SBATCH -N 1
#SBATCH -c 1
#SBATCH --mem=2G
#SBATCH --time=3-00:00:00

source ${SCRIPT_DIR}/slurm/_env.sh

NAME=$1; shift
PORT=$1; shift

CONFIG_PATH="${PREFIX_CONFIG_PATH}/${NAME}"

HOST=`uname -n`
CONDA_ENV=`cat ${CONFIG_PATH}/conda_env`

echo "${HOST}:${PORT}" > "${CONFIG_PATH}/master_host"

conda activate ${CONDA_ENV}
trap "conda deactivate" EXIT

spark-class org.apache.spark.deploy.master.Master -p ${PORT} -h 0.0.0.0
