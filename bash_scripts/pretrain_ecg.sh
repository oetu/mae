#!/usr/bin/bash
# pretraining

# Basic parameters
external="off"

if [ "$external" = "on" ]; then
    batch_size="32"
    accum_iter=(4)
else
    batch_size="128"
    accum_iter=(1)
fi
epochs="400"
warmup_epochs="40"

# Model parameters
input_channels="1"
input_electrodes="12"
time_steps="2500"
model_size="tiny"
model="mae_vit_"$model_size"_patchX"

patch_height="1"
patch_width=(100)

norm_pix_loss="False"

# Augmentation parameters
mask_ratio=(0.8)

jitter_sigma="0.25"
rescaling_sigma="0.5"
ft_surr_phase_noise="0.1"

# Optimizer parameters
blr_array=(1e-5)
weight_decay=(0.15)

# Dataset parameters
data_path="/home/oturgut/sprai/data/preprocessed/ecg/ecgs_train_ecg_imaging_noBase_gn.pt"
labels_path="/home/oturgut/sprai/data/preprocessed/ecg/labelsOneHot/labels_train_CAD_all.pt"

transfer_data_path=""
transfer_labels_path=""

num_workers="32"

# Log specifications
save_output="False"
wandb="True"
wandb_project="MAE_ECG_Pre"

# Checkpoints
resume_from_ckpt="False"
# resume="/home/oturgut/sprai/mae_he/mae/output/pre/noExternal/tiny/2d/t37000/p65x50/m0.75/pre_noExternal_b"$(($batch_size*$accum_iter))"_blr"$blr_array"/checkpoint-450.pth"


for blr in "${blr_array[@]}"
do
    for acc_it in "${accum_iter[@]}"
    do
        for mr in "${mask_ratio[@]}"
        do

            if [ "$external" = "on" ]; then
                folder="ecg/-"
            else
                folder="ecg/noExternal"
            fi

            pre_data="pre_b"$(($batch_size*$acc_it))"_blr"$blr

            subfolder=$model_size"/1d/t"$time_steps"/p"$patch_height"x"$patch_width"/wd"$weight_decay"/m"$mr"/v1"
            output_dir="/home/oturgut/sprai/mae_he/mae/output/pre/"$folder"/"$subfolder"/"$pre_data
            log_dir="/home/oturgut/sprai/mae_he/mae/logs/pre/"$folder"/"$subfolder"/"$pre_data
        
            cmd="python3 main_pretrain.py --jitter_sigma $jitter_sigma --rescaling_sigma $rescaling_sigma --ft_surr_phase_noise $ft_surr_phase_noise --input_channels $input_channels --input_electrodes $input_electrodes --time_steps $time_steps --patch_height $patch_height --patch_width $patch_width --model $model --batch_size $batch_size --epochs $epochs --accum_iter $acc_it --mask_ratio $mr --weight_decay $weight_decay --blr $blr --warmup_epoch $warmup_epochs --data_path $data_path --labels_path $labels_path --log_dir $log_dir --num_workers $num_workers"
            
            if [ "$external" = "on" ]; then
                cmd=$cmd" --transfer_data_path $transfer_data_path --transfer_labels_path $transfer_labels_path"
            fi

            if [ "$norm_pix_loss" = "True" ]; then
                cmd=$cmd" --norm_pix_loss"
            fi

            if [ "$wandb" = "True" ]; then
                cmd=$cmd" --wandb --wandb_project $wandb_project"
            fi

            if [ "$save_output" = "True" ]; then
                cmd=$cmd" --output_dir $output_dir"
            fi

            if [ "$resume_from_ckpt" = "True" ]; then
                cmd=$cmd" --resume $resume"
            fi

            echo $cmd && $cmd

        done
    done
done