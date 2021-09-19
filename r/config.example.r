#!/usr/bin/env Rscript

# Environment Settings --------------------------------------------------------
year <- '2021'
month <- '09'
day <- '09'
base_dir <- '/gpfs/scratch/pr48ze/ge69zeh2'
project  <- 'stilt-playground'

# Slurm Settings --------------------------------------------------------------
slurm_core_count <- 28
slurm_node_count <- 2
slurm_timeout    <- '20:00:00'
slurm_clusters   <- 'cm2_tiny'
slurm_partition  <- 'cm2_tiny'

# Met file settings -----------------------------------------------------------
met_type <- 'ERA5'
met_path <- '/gpfs/scratch/pr48ze/ge69zeh2/stilt-input/hamburg/arl'
map_path <- '/gpfs/scratch/pr48ze/ge69zeh2/stilt-input/hamburg/map'

# Receptor Settings -----------------------------------------------------------
receptor_names <- c(   'mb',    'mc',    'md',    'me')
receptor_types <- c('slant', 'slant', 'slant', 'slant')  # choose either slant, point, or vertical
receptor_lats  <- c( 53.495,  53.536,  53.421,  53.568)  # locations of the instruments
receptor_lngs  <- c( 10.200,   9.677,   9.892,   9.974)
receptor_agls  <- c(     20,      20,      20,      20)  # meters above ground

# Simulation Domain Settings --------------------------------------------------
simulation_t_start         <- paste(year, '-', month, '-', day, ' 06:00:00', sep='')
simulation_t_end           <- paste(year, '-', month, '-', day, ' 18:00:00', sep='')
simulation_t_step          <- '15 mins'
simulation_release_heights <- c(0, 166, 335, 507, 681, 859, 1040, 1224, 1412, 1603, 1798, 1997, 2200)  # release points above the instrument 
simulation_angle_limit     <- 75  # unit:degree