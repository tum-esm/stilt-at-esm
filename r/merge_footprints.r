#USER SETTINGS: 

source('config.r')

rotate_footprints   <- FALSE
integrate_footprint <- TRUE
bk_time_resolution  <- 15*60 #in seconds
level_alt <- 13 # vertical levels
library(ncdf4)

rdf <- readRDS('receptors.rds')
project <- 'stilt-playground'
out_file <- 'footprint.nc'

stilt_wd <- file.path(base_dir, project)
output_wd <- file.path(stilt_wd, 'out/by-id')
fp_wd <- file.path(stilt_wd, 'out/footprints')

#make a list of files:
make_fp_filename <- function(des,run_time,zagl){
        file_id <-  paste0(des, format(run_time , '_%Y%m%d%H%M_' ) , zagl , 'm')
        #in_file_dir <- file.path(fp_wd,file_id)
        return( file.path(fp_wd, paste0( file_id, '_foot.nc') ) )
}

make_bk_filename <- function(des,run_time,zagl){
        file_id <-  paste0(des, format(run_time , '_%Y%m%d%H%M_' ) , zagl , 'm')
        in_file_dir <- file.path(output_wd, file_id)
        return( file.path(in_file_dir, paste0( file_id, '_bbox.rds') ) )
}

rdf$fp_filenames <- mapply( make_fp_filename , rdf$designator , rdf$run_time , rdf$zagl )
rdf$bk_filenames <- mapply( make_bk_filename , rdf$designator , rdf$run_time , rdf$zagl )

rdf <- rdf[ file.exists(rdf$fp_filenames), ]
 #rdf <- rdf[ file.exists(rdf$bk_filenames), ]

recep_times <- sort( unique( as.integer( rdf$run_time ) ) )
designators <- sort( unique( rdf$designator) )

message('receptor times:')
print(recep_times)
message('designators:')
print(designators)

#borrow some things from the file:
nc_in <- nc_open(rdf$fp_filenames[1])
xdim <- nc_in$dim$lon
ydim <- nc_in$dim$lat
xx <- xdim$vals
yy <- ydim$vals

nx <- length(xx)
ny <- length(yy)

#go through all the files and find the needed background times and footprint times
fp_times <- NULL

message('Reading all footprint times...')

for( f in rdf$fp_filenames) {
	nc_in <- nc_open(f)
	fp_times <- c(fp_times,nc_in$dim$tim$vals) 
}
	
fp_times <- sort(unique(fp_times))
message('footprint times: ')
print(fp_times)

raw_bk_times <- NULL
for( f in rdf$bk_filenames) {
		bdf <- readRDS(f)
		raw_bk_times <- c(raw_bk_times, bdf)
}

#raw_bk_times <- sort(unique(raw_bk_times))
message('background range: ')
print(min(raw_bk_times))
print(max(raw_bk_times))
bk_time_breaks <- seq( min(raw_bk_times)-bk_time_resolution , max(raw_bk_times)+bk_time_resolution , by= bk_time_resolution)
bk_times <- head(bk_time_breaks,-1)
message('background bins: ')
print(bk_times)

foot_time_dim  <- ncdim_def('foot_time', 'seconds since 1970-01-01 00:00:00Z',fp_times,calendar='standard')
recep_time_dim <- ncdim_def('recep_time','seconds since 1970-01-01 00:00:00Z',recep_times,calendar='standard')
back_time_dim  <- ncdim_def('back_time', 'seconds since 1970-01-01 00:00:00Z',bk_times,calendar='standard',unlim=TRUE)
nc_vars <- list()

for( des in designators ){
	if(integrate_footprint){
                nc_vars[[paste(des,'foot')]] <- ncvar_def(paste(des,'foot'),'ppm (umol-1 m2 s)',list(xdim,ydim,recep_time_dim),-1)
        }else{
                nc_vars[[paste(des,'foot')]] <- ncvar_def(paste(des,'foot'),'ppm (umol-1 m2 s)',list(xdim,ydim,recep_time_dim,foot_time_dim),-1)
        }
	nc_vars[[paste(des,'BIM')]]  <- ncvar_def(paste(des,'BIM' ),'none',list(back_time_dim,recep_time_dim),-1)
}

BIM <- array(0,dim=c(length(designators),length(bk_times),length(recep_times)))

message("done")

#message('Footprint dimensions: ')
#print(dim(foot))

message('Background Influence Matrix dimensions: ')
print(dim(BIM))

nc_out <- nc_create(out_file, nc_vars, force_v4 = T)

for( row in rownames(rdf) ){
	des <- rdf[row,1]
	recep_time <- rdf[row,2]
	zagl <- rdf[row,5]
	scaling_factor <- rdf[row,6]
	f <- make_fp_filename(des,recep_time,zagl)
        nc_in <- nc_open(f)
	recep_idx <- which( recep_times == recep_time)
        des_idx <- which( designators == des)

	if( integrate_footprint ){
		foot_0 <- ncvar_get(nc_out, nc_vars[[paste(des,'foot')]],
			start = c(1, 1, recep_idx) ,
			count = c(nx,ny,1) )
		ncvar_put(nc_out, nc_vars[[paste(des,'foot')]], 
			foot_0 + ncvar_get(nc_in,'foot')*scaling_factor,
			start = c(1, 1, recep_idx) , 
			count = c(nx,ny,1) )
	}else{
	        fpt_idx1 <- which( fp_times == min(nc_in$dim$tim$vals) )
        	fpt_idx2 <- which( fp_times == max(nc_in$dim$tim$vals) )
        	fpt_length <- 1 + fpt_idx2 - fpt_idx1
	}

	f <- make_bk_filename(des,recep_time,zagl)
	bdf <- readRDS(f)
	bk_hist <- hist(c(NULL,bdf), plot=FALSE, breaks=bk_time_breaks)
	BIM[des_idx,,recep_idx] <-  BIM[des_idx,,recep_idx] + bk_hist$counts # sum up the BIMs for all vertical levels(Xinxu)
}

# vertical mean BIM: average the summed BIMs (Xinxu)

BIM <- BIM/level_alt

for( des in designators){
	des_idx <- which( designators == des)
	ncvar_put(nc_out,nc_vars[[paste(des,'BIM')]], BIM[des_idx, , ])
	ncatt_put(nc_out,paste(des,'foot'), 'standard_name', paste(des,'footprint'))
	ncatt_put(nc_out,paste(des,'foot'), 'long_name', paste(des,'stilt surface influence footprint'))
        ncatt_put(nc_out,paste(des,'BIM'), 'standard_name', paste(des,'BIM'))
        ncatt_put(nc_out,paste(des,'BIM'), 'long_name', paste(des,'background influence matrix'))
}

ncatt_put(nc_out, 0, 'documentation', 'github.com/uataq/stilt')
ncatt_put(nc_out, 0, 'title', 'STILT Footprint')
ncatt_put(nc_out, 0, 'time_created', format(Sys.time(), tz = 'UTC'))

#warnings()
