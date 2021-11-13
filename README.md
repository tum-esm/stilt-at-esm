
## Temporary notes

This repository contains only the files we modified from https://github.com/uataq/stilt (Commit 733d95712072c7a13cfc6a9a0106d712f480c002) to make STILT run automatically on the Linux Cluster @ TUM

Authors (of the modifications): 
- Xinxu Zhao, xinxu.zhao@tum.de
- Moritz Makowski, moritz.makowski@tum.de

Dispatch the job to slurm with:
```bash
module load r/3.6.3-gcc8-mkl
module load netcdf-hdf5-all/4.7_hdf5-1.10-gcc8-impi
Rscript r/run_stilt_modified.r
```

*I will move the code in `r/run_stilt_modified.r` into `r/run_stilt.r`, once the modifications are debugged. The one can see the differences we made immediately with `git diff HEAD 54d9e0d r/run_stilt.r`*

Check the status of the slurm jobs with:
```bash
squeue --clusters cm2_tiny --partitions cm2_tiny
```

<br/>
<br/>

## How to set up STILT at ESM?

TODO ...

1. Set up STILT v2 @ commit sha ...
2. Remove local .git folder
3. git init new repo
4. set remote url to this repo
5. clone with allow files (https://gist.github.com/ZeroDragon/6707408)

<br/>
<br/>

## How has **STILT at ESM** changed from the original STILT v2 codebase

The links in the following list will lead to comparisons between the files in [_STILT v2 @ 733d957_](https://github.com/uataq/stilt/tree/733d95712072c7a13cfc6a9a0106d712f480c002) and the latest version of _STILT at ESM_:

`r/run_stilt.r` has changed:
https://github.com/tum-esm/stilt-at-esm/compare/54d9e0d...master#diff-99df464c93e63dc4b041434685f7574c69493eb8a816c4941b9f3d1dccdacce6

`r/src/simulation_step.r` has changed:
https://github.com/tum-esm/stilt-at-esm/compare/328a82a...master#diff-e086ef3b8df283730533662a4adcb3107ed8bd1a05a1386a458aacb4680eebcc

`r/src/simulation_step.r` has changed:
https://github.com/tum-esm/stilt-at-esm/compare/466966c...master#diff-af94615be17078359a21008c50a38c09ef3c2e2b6470a9def77e51f19e4c8e2b

`r/config.example.r`, `r/config.template.txt`, `r/generate_receptors.r`, `r/merge_footprints.r` have been added to the codebase (not included in STILT v2).
