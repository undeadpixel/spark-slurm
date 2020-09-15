#!/bin/bash -l

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${SCRIPT_DIR}/slurm/_env.sh

print_help() {
cat << EOM
  start_worker.sh [options]
    -h | --help                     Print this help.
      -n | --name                     Name of the spark server instance.
    -e | --conda-env                Name of the conda env to use.
    -c | --worker-cpus              Number of cpus to use for each worker (DEFAULT: 8).
    -m | --worker-mem               Size of the memory reserved for each worker (in GB) (DEFAULT: 30).
                                    NOTE: remember that SLURM is extremely strict and java quite lax,
                                    reserve more memory than needed and allocate the executors less.
                                    Moreover, the servers don't have a power of 2 size of RAM, so 32 should be 30.
                                    Then, the spark worker will be using 28.
    -p | --port                     Port number to use (DEFAULT: 7077)
EOM
  exit
}

PORT=7077
WORKER_CPUS=8
WORKER_MEM=30

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_help
    ;;
    -n|--name)
      NAME=$2
      shift;shift
    ;;
    -e|--conda-env)
      CONDA_ENV=$2
      shift;shift
    ;;
    -p|--port)
      PORT=$2
      shift;shift
    ;;
    -c|--cpus)
      WORKER_CPUS=$2
      shift;shift
    ;;
    -m|--mem)
      WORKER_MEM=$2
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

if [ -z $CONDA_ENV ]; then
  echo "CONDA_ENV (-e / --conda-env) must be present."
  print_help
fi

CONFIG_PATH="${PREFIX_CONFIG_PATH}/${NAME}"
if [ -d ${CONFIG_PATH} ]; then
  echo "Server already exists, or it has not been deleted accordingly."
  exit
fi

LOGS_PATH="${CONFIG_PATH}/logs"
mkdir -p ${LOGS_PATH}
echo "0" > "${CONFIG_PATH}/current_worker_id"
echo ${CONDA_ENV} > "${CONFIG_PATH}/conda_env"

echo ${WORKER_CPUS} > "${CONFIG_PATH}/worker_cpus"
echo ${WORKER_MEM} > "${CONFIG_PATH}/worker_mem"

sbatch \
--job-name="spark.${NAME}.master" \
--output="${LOGS_PATH}/master.log" \
--export="ALL,SCRIPT_DIR=${SCRIPT_DIR}" \
${SCRIPT_DIR}/slurm/_master.sh ${NAME} ${PORT}

echo -n "> Waiting for the job to be started "
while [ ! -e "${CONFIG_PATH}/master_host" ]; do
  sleep 1
  echo -n "."
done

echo ""
echo -n "Host: "
cat "${CONFIG_PATH}/master_host"