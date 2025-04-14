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

# 3. COUNTRY POLYGON
#-------------------

country_sf <- geodata::gadm(
  country = "BWA", level = 0,
  path = main_dir
) |>
  sf::st_as_sf()

# 4. CROP AND RESAMPLE
#---------------------

# define the target CRS
target_crs <- "EPSG:4209"

# crop the input raster to the
# country's extent and apply a mask
temp_prec_country <- terra::crop(
  temp_prec, country_sf,
  mask = TRUE
)

# Obtain AWS tiles DEM data from elevatr
# convert to terra SpatRaster and crop
dem <- elevatr::get_elev_raster(
  locations = country_sf, z = 8,
  clip = "locations"
) |> terra::rast() |>
  terra::crop(country_sf, mask = TRUE)

# resample the raster to match DEM resolution
# using bilinear interpolation, then reproject

temp_prec_resampled <- terra::resample(
  x = temp_prec_country,
  y = dem, method = "bilinear"
) |> terra::project(target_crs)

# plot the resampled raster
terra::plot(temp_prec_resampled)

# convert the raster to dataframe with coordinates
temp_prec_df <- as.data.frame(
  temp_prec_resampled, xy = TRUE
)
