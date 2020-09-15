PREFIX_PATH="${HOME}/.spark-slurm"
PREFIX_CONFIG_PATH="${PREFIX_PATH}/servers"
PREFIX_ENV_PATH="${PREFIX_PATH}/envs"

mem_worker() {
  python -c "import math; print(math.ceil(${1}*0.9) - 1)"
}