#!/bin/bash
eval "$(command conda 'shell.bash' 'hook' 2> /dev/null)"

########## globals ##########
dataset="s2.0.0"
envFile="environment.yml"
envName="brepnet"
ncores=`nproc --all`
questionList=(
    "Clone BRepNet"
    "Create conda environment"
    "Prepare dataset"
    "Reproduce paper results")
cmdList=(
    "cloneRepo"
    "createEnvironment"
    "prepareData"
    "reproducePaper")


########## command functions ##########
cloneRepo() {
    git clone https://github.com/AutodeskAILab/BRepNet.git
}

createEnvironment() {
    conda update anaconda -y
    conda update conda -y
    conda update python -y
    conda config --add channels conda-forge
    conda install -n base mamba -c conda-forge --yes
    cd BRepNet
    mamba env create -f ${envFile}
    cd ../
}

prepareData() {
    cd BRepNet
    curl https://fusion-360-gallery-dataset.s3-us-west-2.amazonaws.com/segmentation/${dataset}/${dataset}.zip -o ${dataset}.zip;
    unzip ${dataset}.zip
    rm -rf ${dataset}.zip
    conda activate ${envName}
    python -m pipeline.quickstart --dataset_dir ${dataset} --num_workers $ncores
    cd ../
}

reproducePaper() {
    conda activate ${envName}
    cd BRepNet
    python -m train.train \
        --dataset_file ${dataset}/processed/dataset.json \
        --dataset_dir  ${dataset}/processed/ \
        --num_layers 2 \
        --use_face_grids 0 \
        --use_edge_grids 0 \
        --use_coedge_grids 0 \
        --use_face_features 1 \
        --use_edge_features 1 \
        --use_coedge_features 1 \
        --dropout 0.0 \
        --max_epochs 50 \
        --num_workers $ncores
    cd ../
}

runAllCommands() {
    for i in "${!cmdList[@]}"; do
        cmd=${cmdList[$i]}
        eval $cmd
    done
}

########## main execution loop ##########
ulimit -Sn 50000

# choose express install or custom
read -p "Express install? [y/n] " yn
if [ ${yn} == 'y' ]; then
    eval runAllCommands
else
    # custom install
    for i in "${!questionList[@]}"; do
        question=${questionList[$i]}
        cmd=${cmdList[$i]}
        while true; do
            read -p "${question}? [y/n] " yn
            case $yn in
                [Yy]* ) eval $cmd; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no";;
            esac
        done
    done
fi
