#!/bin/bash -l

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${SCRIPT_DIR}/slurm/_env.sh

print_help() {
cat << EOM
  start_worker.sh [options]
    -h | --help                     Print this help.
    -n | --name                     Name of the spark server instance.
    -c | --num                      Number of workers to start (DEFAULT: 1)
    -t | --time                     Amount of time the worker is active (DEFAULT: 01-00:00:00)
EOM
  exit
}

TIME="01-00:00:00"
NUM=1

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_help
    ;;
    -n|--name)
      NAME=$2
      shift;shift
    ;;
    -t|--time)
      TIME=$2
      shift;shift
    ;;
    -c|--num)
      NUM=$2
      shift;shift
    ;;
    *)
      shift
    ;;
  esac
done

if [ -z $NAME ]; then
  echo "NAME (-n / --name) must be present."
  print_help
fi

CONFIG_PATH="${PREFIX_CONFIG_PATH}/${NAME}"
if [ ! -d ${CONFIG_PATH} ]; then
  echo "Server has not started."
  exit
fi

CPUS=`cat ${CONFIG_PATH}/worker_cpus`
MEM=`cat ${CONFIG_PATH}/worker_mem`

for I in $(seq 1 ${NUM}); do
  CURRENT_WORKER_ID_PATH="${CONFIG_PATH}/current_worker_id"
  ID=`cat ${CURRENT_WORKER_ID_PATH}`
  echo $((ID + 1)) > ${CURRENT_WORKER_ID_PATH}
  
  echo "> Starting worker #${ID} with (cpu=${CPUS}, mem=${MEM})"
  sbatch \
  --job-name="spark.${NAME}.worker.${ID}" \
  --output="${CONFIG_PATH}/logs/worker.${ID}.log" \
  --export="ALL,SCRIPT_DIR=${SCRIPT_DIR}" \
  -c ${CPUS} --mem=${MEM}g -N 1 --time=${TIME} \
  ${SCRIPT_DIR}/slurm/_worker.sh ${NAME} ${ID} ${CPUS} ${MEM}
done
