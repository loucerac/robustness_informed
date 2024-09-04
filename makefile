#!make
include .env
.PHONY: install-ivae format run-kegg run-reactome run-random run-scoring-kegg run-scoring-reactome run-scoring-random
.ONESHELL:

SHELL := /bin/bash
FRACS=$$(LANG=en_US seq ${FRAC_START} ${FRAC_STEP} ${FRAC_STOP})
SEEDS=$$(LANG=en_US seq ${SEED_START} ${SEED_STEP} ${SEED_STOP})
PY_FILES := isrobust/*.py

all: | install-ivae format run-kegg  run-reactome  run-random  run-scoring-kegg  run-scoring-reactome  run-scoring-random

install-ivae:
	pixi install

format: install-ivae
	pixi run ruff check . --fix
	pixi run ruff check --select I --fix .
	pixi run ruff format .

run-kegg: install-ivae format
	rm -rf results/ivae_kegg
	mkdir -p results/ivae_kegg/logs/
	parallel -j${N_GPU} CUDA_VISIBLE_DEVICES='$$(({%} - 1))' \
		pixi run python notebooks/00-train.py ivae_kegg ${DEBUG} {} \
		">" results/ivae_kegg/logs/train_seed-{}.out \
		"2>" results/ivae_kegg/logs/train_seed-{}.err \
		::: $(SEEDS)

run-reactome: install-ivae format
	rm -rf results/ivae_reactome
	mkdir -p results/ivae_reactome/logs
	parallel -j${N_GPU} CUDA_VISIBLE_DEVICES='$$(({%} - 1))' \
		pixi run python notebooks/00-train.py ivae_reactome ${DEBUG} {} \
		">" results/ivae_reactome/logs/train_seed-{}.out \
		"2>" results/ivae_reactome/logs/train_seed-{}.err \
		::: $(SEEDS)

run-random: install-ivae format
	rm -rf $$(printf "results/ivae_random-%s " $(FRACS))
	mkdir -p $$(printf "results/ivae_random-%s/logs " $(FRACS))

	parallel -j${N_GPU} CUDA_VISIBLE_DEVICES='$$(({%} - 1))' \
		pixi run python notebooks/00-train.py ivae_random-{2} ${DEBUG} {2} {1} \
		">" results/ivae_random-{2}/logs/train_seed-{1}.out \
		"2>" results/ivae_random-{2}/logs/train_seed-{1}.err \
		::: $(SEEDS) \
		::: $(FRACS)

run-scoring-kegg: run-kegg

	pixi run papermill notebooks/01-compute_scores.ipynb - \
		-p model_kind ivae_kegg \
		> results/ivae_kegg/logs/scoring.out \
		2> results/ivae_kegg/logs/scoring.err

run-scoring-reactome: run-reactome

	pixi run papermill notebooks/01-compute_scores.ipynb - \
		-p model_kind ivae_reactome \
		> results/ivae_reactome/logs/scoring.out \
		2> results/ivae_reactome/logs/scoring.err

run-scoring-random:
	parallel -j${N_CPU} \
		pixi run papermill notebooks/01-compute_scores.ipynb - \
		-p model_kind ivae_random-{} -p frac {} \
		">" results/ivae_random-{}/logs/scoring.out \
		"2>" results/ivae_random-{}/logs/scoring.err \
		::: $(FRACS)
