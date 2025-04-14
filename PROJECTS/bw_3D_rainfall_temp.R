getwd()
# 1. PACKAGES
#------------------
install.packages("remotes")
remotes::install_github(
  "inSileco/rchelsa"
)
remotes::install_github(
  "chris-prener/biscale"
)

# install and load all packages
pacman::p_load(
  geodata, tidyverse, sf, terra,
  rchelsa, biscale, elevatr, cowplot,
  gridGraphics, rayshader
)

# 2. CHELSA DATA
#----------------

# set the working directory
main_dir <- getwd()

# define a vector of IDs to download
ids <- c(1, 12)

# function to download CHELSA data
download_chelsa_data <- function(id, path){
  rchelsa::get_chelsea_data(
    categ = "clim", type = "bio",
    id = id, path = path
  )
}

# download data for each id
lapply(ids, download_chelsa_data, path = main_dir)

list.files()

# load the raster files
temp <- terra::rast("CHELSA_bio10_01.tif")
prec <- terra::rast("CHELSA_bio10_12.tif")

# average precipitation
prec_average <- prec / 30

# Combine average temperature and precipitation
# into a raster stack
temp_prec <- c(temp, prec_average)

# assign names to each layer in the stack
names(temp_prec) <- c("temperature", "precipitation")
