#!/bin/bash -l

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${SCRIPT_DIR}/slurm/_env.sh

yes_no() {
  while true; do
    read -p "" YES_NO
    case $YES_NO in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes or no";;
    esac
  done
}

function print_help {
  echo "cancel.sh ACTION={all,workers} NAME"
  exit
}

if [ $# -lt 2 ]; then
  print_help
  exit
fi

ACTION=$1
shift
NAME=$1

FILTER="spark.${NAME}"
case ${ACTION} in
  all ) FILTER="${FILTER}.\(master\|worker\)";;
  workers ) FILTER="${FILTER}.worker";;
  * ) echo "Unknown action '${ACTION}'"; print_help ;;
esac

TASKS_TO_STOP=`squeue -hu $USER -o "%A %j" | grep ${FILTER} | cut -f 2 -d " "`
IDS_TO_STOP=`squeue -hu $USER -o "%A %j" | grep ${FILTER} | cut -f 1 -d " "`
if [ -z "$TASKS_TO_STOP" ]; then
  echo "> STOPPING. There are no tasks with this name..."
  exit
fi

for TASK in $TASKS_TO_STOP; do
  echo "- ${TASK}"
done

echo -n "> Stopping tasks (y/n) "
if yes_no; then
  scancel ${IDS_TO_STOP}
  if [ ${ACTION} == "all" ]; then
    sleep 3
    rm -fr "${PREFIX_CONFIG_PATH}/${NAME}"
  fi
fi
