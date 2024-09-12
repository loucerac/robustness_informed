# robustness_informed


## setup

Install `pixi`: https://pixi.sh/latest/

## Experiment

The `.env` file used:

```
IVAE_ENV_FOLDER=./.venvs/ivae
BINN_ENV_FOLDER=./.venvs/binn
N_GPU=3
N_CPU=30
FRAC_START=0.05
FRAC_STOP=0.9
FRAC_STEP=0.05
SEED_START=0
SEED_STOP=99
SEED_STEP=1
DEBUG=0
RESULTS_FOLDER=${HOME}/mnt/output/robustness_informed
```

It was run using:
```
screen -d -m make
```
