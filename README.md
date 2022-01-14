
# STILT at ESM

## What is it?

This repository contains only the files we modified from [STILT v2](https://github.com/uataq/stilt) (Commit 9524fe765d261710041014548c4056323c3e3655) to make STILT run for out total column measurement approach.

Authors of these modifications: 
- Xinxu Zhao, xinxu.zhao@tum.de
- Moritz Makowski, moritz.makowski@tum.de

<br/>
<br/>

## How to set it up?

**1.** Set up STILT v2 (https://uataq.github.io/stilt/#/quick-start) with the following modifications:

```bash
# 1. instead of
Rscript -e "install.packages('devtools'); devtools::install_github('benfasoli/uataq')"
# you should use
Rscript -e "install.packages('devtools', repos='http://cran.us.r-project.org'); devtools::install_github('uataq/uataq@f025aaddff195239f2c51d19a5f169b70335e000')"

# 2. instead of
Rscript -e "uataq::stilt_init('myproject')"
# you should use
Rscript -e "uataq::stilt_init('myproject', repo='--depth 200 https://github.com/uataq/stilt myproject && cd myproject && git checkout 9524fe765d261710041014548c4056323c3e3655 && cd .. && echo')"
```

**2.** cd into to project directory

```bash
cd myproject
``` 

**3.** Install all dependencies for STILT v2 so that the following tests pass

```bash
bash test/test_setup.sh
bash test/test_run_stilt.sh
```

**4.** Remove `.git` folder and all unused files:

```bash
rm -rf .git && rm -rf .github && rm -rf docs && rm -rf test && rm setup
```

**5.** Pull our modifications into the directory

```bash
git init
git remote add origin https://github.com/tum-esm/stilt-at-esm.git
git fetch origin main
git reset --hard origin/main
```

<br/>
<br/>

## How to run it?

**1.** Use the file `r/config.example.r` to create a file `r/config.r` for your setup

**2.** Create a list of discrete column receptors
```bash
Rscript r/create_receptors.r  # will generate a file named receptors.rds
```

**3.** Dispatch the job to SLURM
```bash
Rscript r/run_stilt.r
```

**4.** Check the status of the SLURM jobs with:
```bash
squeue --clusters ... --partitions ...
```

**5.** After STILT is finished, merge the discrete column footprints into one total column footprint
```bash
Rscript r/merge_receptors.r  # will generate a file named footprint.nc
```

<br/>
<br/>

## How has **STILT at ESM** changed from the original **STILT v2** codebase?

You can use [git diff](https://git-scm.com/docs/git-diff) to compare how individual files have changed between commits. The following lists include all changes from [_STILT v2 @ 733d957_](https://github.com/uataq/stilt/tree/733d95712072c7a13cfc6a9a0106d712f480c002).

How files have changed:
* **`r/run_stilt.r`**: `git diff 54d9e0d HEAD r/run_stilt.r`
* **`r/src/simulation_step.r`:** `git diff 328a82a HEAD r/src/simulation_step.r`
* **`r/src/write_control.r`:** `git diff 466966c HEAD r/src/write_control.r`

What files have been added (not included in STILT v2):
* **`r/config.example.r`**
* **`r/config.template.txt`**
* **`r/generate_receptors.r`**
* **`r/merge_footprints.r`**
