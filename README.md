**⚠️ Internally Replaced by https://github.com/tum-esm/stilt**

---

# STILT at ESM

## What is it?

This repository contains only the files we modified from [STILT v2](https://github.com/uataq/stilt) (Commit 9524fe765d261710041014548c4056323c3e3655) to make STILT run for out total column measurement approach.

Authors of these modifications: 
- Xinxu Zhao, xinxu.zhao@tum.de
- Moritz Makowski, moritz.makowski@tum.de

<br/>
<br/>

## How to set it up?

**1.** Clone this repository

```bash
git clone https://github.com/tum-esm/stilt-at-esm
```

**2.** Check whether the correct versions of `r` and `netcdf` are present on your system. You might have to adjust line `13` in the script `install.sh` depending on your setup.

**3.** Install the project

```
cd stilt-at-esm
bash ./install.sh
```

<br/>
<br/>

If this is the first time that you install this project in a certain environment you should probably check whether the STILT v2 tests have passed. In `install.sh` you can uncomment line `25` to stop the installation at that command in order to see whether the tests have been successful.

The installation script is idempotent (can be run multiple times without any effect): At the beginning of its execution it removes all files that are ignored by this git project (= all files generated during its execution).

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
