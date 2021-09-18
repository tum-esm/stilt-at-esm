#this script generates a receptor list file for em27s. 

require(insol)      #needed to compute solar elevation and azimuth angles
require(geosphere)  #needed to compute the lat-lon offset from these angles

t_start_original <- '2021-09-09 06:00:00'  #first particle release
t_end_original   <- '2021-09-09 18:00:00'  #last  particle release
t_step  <- '15 mins' #'15 mins'

#Munich 2020
designators  <- c('mb','mc','md','me')
release_type <- c('slant','slant','slant','slant') # choose either slant, point, or vertical
latitudes    <- c(53.495,53.536,53.421,53.568)    #location of the instruments
longitudes   <- c(10.200,9.677,9.892,9.974)   #
sensor_agls  <- c(20,20,20,20)  #meters above ground for each instrument (building height)
relative_release_heights <- c(0,166,335,507,681,859,1040,1224,1412,1603,1798,1997,2200) #release points above the instrument 
file_name <- 'HAM_20210909_receptors_ERA5.rds' #output of this program
angle_limit <- 75 #unit:degree

#The .map file from the em27 retrieval contains the vertical profile
vertical_profile <- 'map' # select either 'map' or 'met'
map_directory    <- '/dss/dsstumfs01/pn69ki/pn69ki-dss-0004/STILT/map/HAM/'
met_directory    <- '/dss/dsstumfs01/pn69ki/pn69ki-dss-0004/STILT/Hamburg/arl/'

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

#compute the vertical scaling factors:
doi <- format ( run_times[1] , '%Y%m%d' )
Av <- 6.022140857e23 #molec. / mol
g0 <- 9.8 # m/s2
m_air <- .029 #kg /mol
mapCols <- c('Height','Temp','Pressure','Density','h2o','hdo','co2','n2o','co','ch4','hf','gravity')
map <- read.table( paste(map_directory,'L1',doi,'.map',sep=''), skip=11,col.names=mapCols,stringsAsFactors=FALSE,sep=',' )
densFunc <- splinefun(x=map$Height,y=map$Density)
pressure_function <- splinefun(x=map$Height, y=map$Pressure)

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


add_scaling_factor <- function(zagl,designator){
	sensor_agl <- sensor_agls[ which(designators == designator) ]
# Taylor's original code should be kept here, if you could run a case which holds the same pressure differencec:
	air_column <- pressure_function( sensor_agl/1000.0 )*100*Av/(g0*m_air) #molec. / m2. Total molecules in column
	z_high <- sensor_agl
	release_heights <- relative_release_heights+sensor_agl

	n_of_z <- densFunc( as.numeric(release_heights)/1000.0 )*100*100*100  # molec. / m3
	dz <- NA

	for( i in 1:(length(release_heights)-1)) {
		z_low  <- z_high	
		z_high <- mean( as.numeric( release_heights[i:i+1] ) )
		dz[i]  <- z_high - z_low
	}

	dz[i+1] <- z_high - z_low

	vertical_scaling_factors <- n_of_z*dz/air_column

	zagl_index <- which(release_heights == zagl)
	return( vertical_scaling_factors[zagl_index])
}
	
recep_lat_lon <- mapply( make_receptors, df$relative_z, df$designator, df$run_time ) 

df['long'] <- round(recep_lat_lon[1,],3)
df['lati'] <- round(recep_lat_lon[2,],3)
df['zagl'] <- mapply( add_zagl , df$relative_z, df$designator )

df['scaling_factors'] <- mapply( add_scaling_factor, df$zagl, df$designator)

df['relative_z'] <- NULL

saveRDS(df,file_name)

