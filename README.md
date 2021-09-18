This repository contains only the files we modified from https://github.com/uataq/stilt (Commit 733d95712072c7a13cfc6a9a0106d712f480c002) to make STILT run automatically on the Linux Cluster @ TUM

Authors (of the modifications): 
- Xinxu Zhao, xinxu.zhao@tum.de
- Moritz Makowski, moritz.makowski@tum.de

Dispatch the job to slurm with:
```bash
module load r/3.6.3-gcc8-mkl
Rscript r/run_stilt_modified.r
```

*I will move the code in `r/run_stilt_modified.r` into `r/run_stilt.r`, once the modifications are debugged. The one can see the differences we made immediately with `git diff HEAD 54d9e0d r/run_stilt.r`*

Check the status of the slurm jobs with:
```bash
squeue --clusters cm2_tiny --partitions cm2_tiny
```
