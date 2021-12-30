# this script generates a receptor list file for em27s. 

require(insol)      # needed to compute solar elevation and azimuth angles
require(geosphere, warn.conflicts = FALSE)  # needed to compute the lat-lon offset from these angles

source('r/config.r')

t_start_original <- simulation_t_start
t_end_original   <- simulation_t_end
t_step           <- simulation_t_step

designators  <- receptor_names
release_type <- receptor_types
latitudes    <- receptor_lats
longitudes   <- receptor_lngs
sensor_agls  <- receptor_agls

relative_release_heights <- simulation_release_heights
angle_limit <- simulation_angle_limit
file_name <- 'receptors.rds' # output of this program

# The .map file from the em27 retrieval contains the vertical profile
vertical_profile <- 'map' # select either 'map' or 'met'
map_directory    <- map_path
met_directory    <- met_path

#------------------------------------------------
# END OF USER INPUTS
#------------------------------------------------

# add the criteria here to define the appropriate running period:

run_times_original <- seq(from = as.POSIXct(t_start_original, tz='UTC'),to = as.POSIXct(t_end_original, tz='UTC'),by = t_step )

#distance_original <- function(release_heights, designator, run_time){
#  des_idx = which(designators == designator)
#  s_vec <- sunvector(JD(run_time),latitudes[des_idx],longitudes[des_idx],0)
#  az_sza <- sunpos( s_vec )
#  return(max(relative_release_heights)/1000*tan(pi*az_sza[2]/180) )
#}
sza_original <- function(release_heights, designator, run_time){
   des_idx = which(designators == designator)
   s_vec <- sunvector(JD(run_time),latitudes[des_idx],longitudes[des_idx],0)
   az_sza <- sunpos( s_vec )
   return(az_sza[2] )
}

df_original <- expand.grid(relative_release_heights,designators,run_times_original,stringsAsFactors=FALSE)

colnames(df_original) <- c('heights','designator','run_time_original')

#df_original ['dist'] <- mapply(distance_original, df_original$heights, df_original$designator, df_original$run_time_original) 
df_original ['sza'] <- mapply(sza_original, df_original$heights, df_original$designator, df_original$run_time_original) 

#df_original_edited<-subset(df_original ,df_original ['dist'] < distance_limit & df_original ['dist'] > 0)
df_original_edited<-subset(df_original ,df_original ['sza'] < angle_limit & df_original ['sza'] > 0)

receptor_times <- sort(unique(df_original_edited$run_time_original))

t_end <- max(receptor_times)

t_start <- min(receptor_times)

#------------------------------------------------

run_times <- seq(from = as.POSIXct(t_start, tz='UTC'),to = as.POSIXct(t_end, tz='UTC'),by = t_step )

### VERTICAL SCALING FACTOR RELATED:

#load map-file:
mapCols <- c('Height','Temp','Pressure','Density','h2o','hdo','co2','n2o','co','ch4','hf','gravity')
map <- read.table(
	file.path(map_directory, paste('L1', format (run_times[1], '%Y%m%d'), '.map', sep='')),
	skip=11, col.names=mapCols, stringsAsFactors=FALSE, sep=','
)

# density function of vertical densities
densFunc <- splinefun(x=map$Height,y=map$Density)

# apply exponential fit to last 10 altitude elements
exp_fit <- nls(Density ~ b * exp(-1/c*Height),data=tail(map, n=10) ,start=list(b=2.5e19,c=7.4))
#plot(map$Density,map$Height)
#lines(predict(exp_fit, list(Height = map$Height)),map$Height, col = "red")

#integrate
integrate <- function(myfun,lower,upper,resolution=1000){
  # equally spaced x-bins (resolution)
  # multiplied by function-value, evaluated in the middle of x-bins
  dx <- (upper-lower)/resolution
  x <- seq(from=lower+dx/2,to=upper-dx/2,by=dx)
  return(sum(myfun(x)*dx))
}

# top of atmosphere integrate exponential function up to 7000km (very small contribution)
toa_exp <- integrate(function(x)predict(exp_fit, list(Height = x)),max(map$Height),7000,1e6)

#integration borders for given relative_release_heights:
ib <- c(0)
for (i in seq(1,length(relative_release_heights)-1)){
  
  ib <- c(ib,0.5*(relative_release_heights[i]+relative_release_heights[i+1]))
  
}
ib <- c(ib,tail(relative_release_heights,n=1)+0.5*diff(tail(relative_release_heights,n=2)))

#plot(densFunc(ib/1000),ib,col='red')
#points(densFunc(relative_release_heights/1000),relative_release_heights)

# integrate all:
get_scfs <- function(ib,precision=1e5){
  scf <- c()
  for (i in seq(1,length(relative_release_heights))){
    zl <- ib[i]
    zh <- ib[i+1]
     scf <- c(scf,integrate(densFunc,zl,zh,precision))
  }
  
  # integral above highest receptor to top of atmosphere:
  toa <- integrate(densFunc,tail(ib,n=1)/1000,max(map$Height),1e5)+toa_exp
  
  # norm scf by molecules above
  scf <- scf/toa
  
  return (scf)
}

#calculate scaling factors
df_scf <- expand.grid(relative_release_heights,designators)
names(df_scf) <- c('heights','designator')
df_scf$zagl <- sensor_agls[ match(df_scf$designator,designators) ]
df_scf$scf <- NA
for (designator in designators){
  m <- df_scf$designator==designator
  zagl <- sensor_agls[which(designators==designator)]
  scfs <- get_scfs((ib+zagl)/1000)
  df_scf[m,'scf'] <- scfs[match(df_scf$heights[m],relative_release_heights)]
}

add_scf <- function(height,designator){
  return(df_scf[(df_scf$heights==height) & (df_scf$designator==designator),'scf'])
}

### END VERTICAL SCALING FACTOR ###

df <-  expand.grid(relative_release_heights,designators,run_times,stringsAsFactors=FALSE)
colnames(df) <- c('relative_z','designator','run_time')

make_receptors <- function(relative_z,designator,run_time){
	des_idx = which(designators == designator)
	s_vec <- sunvector(JD(run_time),latitudes[des_idx],longitudes[des_idx],0)
	az_sza <- sunpos( s_vec )
	return( destPoint( c(longitudes[des_idx],latitudes[des_idx]) ,az_sza[1], relative_z*tan(pi*az_sza[2]/180) ) ) 
}


add_zagl <- function(relative_z,designator){
	sensor_agl <- sensor_agls[ which(designators == designator) ]
	return( relative_z + sensor_agl )
}



recep_lat_lon <- mapply( make_receptors, df$relative_z, df$designator, df$run_time ) 

df['long'] <- round(recep_lat_lon[1,],3)
df['lati'] <- round(recep_lat_lon[2,],3)
df['zagl'] <- mapply( add_zagl , df$relative_z, df$designator )

df['scaling_factors'] <- mapply( add_scf,df$relative_z,df$designator)

df['relative_z'] <- NULL

saveRDS(df,file_name)

