#!/bin/bash
#$ -l rt_AF=1
#$ -l h_rt=24:00:00
#$ -l USE_SSH=1
#$ -v SSH_PORT=2200
#$ -j y
#$ -o outputs/
#$ -cwd

source /etc/profile.d/modules.sh
module load cuda/11.8/11.8.0
module load cudnn/8.9/8.9.2
module load nccl/2.16/2.16.2-1
module load hpcx/2.12

cd /bb/llm/gaf51275/llama/llm-jp-sft/
source .env/bin/activate

accelerate launch --config_file configs/accelerate_config_zero1.yaml \
    train.py \
    --num_train_epochs 5 \
    --per_device_train_batch_size 2 \
    --gradient_accumulation_steps 8 \
    --learning_rate 1e-5 \
    --warmup_ratio 0.05 \
    --lr_scheduler_type cosine \
    --bf16 \
    --max_seq_length 2048 \
    --logging_steps 1 \
    --data_files /bb/llm/gaf51275/llama/llm-jp-sft/data/llama2_project_data/train_data_instruct.jsonl \
    --eval_data_files /bb/llm/gaf51275/llama/llm-jp-sft/data/llama2_project_data/val_data_instruct.jsonl \
    --model_name_or_path llm-jp/llm-jp-1.3b-v1.0 \
    --output_dir results/llm-jp-1.3b-instruct-full-test