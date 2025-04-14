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
