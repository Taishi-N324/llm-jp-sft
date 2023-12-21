#!/bin/bash
#$ -l rt_AF=4
#$ -l h_rt=48:00:00
#$ -l USE_SSH=1
#$ -v SSH_PORT=2200
#$ -j y
#$ -o outputs/
#$ -cwd

# module load
source /etc/profile.d/modules.sh
module load cuda/11.8/11.8.0
module load cudnn/8.9/8.9.2
module load nccl/2.16/2.16.2-1
module load hpcx/2.12

cd /bb/llm/gaf51275/llama/llm-jp-sft/
source .env/bin/activate
# distributed settings
export MASTER_ADDR=$(/usr/sbin/ip a show dev bond0 | grep 'inet ' | awk '{ print $2 }' | cut -d "/" -f 1)
export MASTER_PORT=$((10000 + ($JOB_ID % 50000)))
export CUDA_DEVICE_MAX_CONNECTIONS=1

echo "MASTER_ADDR=${MASTER_ADDR}"

# hostfile
NUM_NODES=$NHOSTS
NUM_GPU_PER_NODE=4
ssh_port=2200

function run_slave_node() {
    local rank=1

    cat ${SGE_JOB_HOSTLIST} | grep -v $HOSTNAME | while read node; do
		ssh -p $ssh_port $node \
        	"bash /bb/llm/gaf51275/llama/llm-jp-sft/abci/remote_train.sh $rank $MASTER_ADDR $MASTER_PORT" &
        rank=$((rank+1))
    done
}

function run_master_node() {
    local rank=0
    accelerate launch --config_file configs/accelerate_config_zero3.4node.yaml \
    --main_process_ip $MASTER_ADDR \
    --main_process_port $MASTER_PORT \
    --machine_rank $rank \
    train.py \
    --num_train_epochs 5 \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 4 \
    --learning_rate 1e-5 \
    --warmup_ratio 0.05 \
    --lr_scheduler_type cosine \
    --bf16 \
    --max_seq_length 2048 \
    --logging_steps 1 \
    --data_files /bb/llm/gaf51275/llama/llm-jp-sft/data/llama2_project_data/train_data_instruct.jsonl \
    --eval_data_files /bb/llm/gaf51275/llama/llm-jp-sft/data/llama2_project_data/val_data_instruct.jsonl \
    --model_name_or_path llm-jp/llm-jp-13b-v1.0 \
    --output_dir results/llm-jp-13b-instruct-full-llama2-project
}


function main() {
    run_slave_node
    run_master_node

    wait
}

main
