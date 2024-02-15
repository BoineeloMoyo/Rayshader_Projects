#############################################
# 01. Loading required Libraries

packages <- c("tidyverse", "stars", "terra", "sf", "ggplot2", "httr2", "tmap")

package.check <- lapply(packages, function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  }
})

# 1. DOWNLOAD THE ETH DATA AND LOAD IT

raster_files <-
  list.files(
    path = getwd(),
    pattern = "GlobalCanopyHeight",
    full.names = T
  )

# 2. Get the Lower Saxony boundary from GADM

get_state_boundary <- function() {
  main_path <- getwd()
  state_boundary <- geodata::gadm(
    country = "DEU",  
    level = 1,
    path = main_path
  ) |>
    sf::st_as_sf()
  
  return(state_boundary)
}

state_boundary <- get_state_boundary()
unique(
  state_boundary$NAME_1
)

niedersachsen_sf <- state_boundary |>
  dplyr::filter(
    NAME_1 == "Niedersachsen"  
  ) |>
  sf::st_union()

plot(sf::st_geometry(
  niedersachsen_sf
))


# 3. Loading the forest data 

forest_height_list <- lapply(
  raster_files,
  terra::rast
)

forest_height_rasters <- lapply(
  forest_height_list,
  function(x) {
    terra::crop(
      x,
      terra::vect(
        niedersachsen_sf
      ),
      snap = "in",
      mask = T
    )
  }
)

forest_height_mosaic <- do.call(
  terra::mosaic,
  forest_height_rasters
)

forest_height_ni <- forest_height_mosaic |>
  terra::aggregate(
    fact = 10
  )


forest_height_ni_df <- forest_height_ni |>
  as.data.frame(
    xy = T
  )

head(forest_height_ni_df)
names(forest_height_ni_df)[3] <- "height"

class(forest_height_ni_df$height)


# 5. BREAKS

breaks <- classInt::classIntervals(
  forest_height_ni_df$height,
  n = 5,
  style = "fisher"
)$brks



cols <-
  c(
    "white", "#ffd3af", "#fbe06e",
    "#6daa55", "#205544"
  )

texture <- colorRampPalette(
  cols,
  bias = 2
)(6)

# 7. GGPLOT2
#-----------

p <- ggplot(
  forest_height_ni_df
) +
  geom_raster(
    aes(
      x = x,
      y = y,
      fill = height
    )
  ) +
  scale_fill_gradientn(
    name = "height (m)",
    colors = texture,
    breaks = round(breaks, 0)
  ) +
  coord_sf(crs = 4326) +
  guides(
    fill = guide_legend(
      direction = "vertical",
      keyheight = unit(5, "mm"),
      keywidth = unit(5, "mm"),
      title.position = "top",
      label.position = "right",
      title.hjust = .5,
      label.hjust = .5,
      ncol = 1,
      byrow = F
    )
  ) +
  theme_minimal() +
  theme(
    axis.line = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    legend.position = "right",
    legend.title = element_text(
      size = 11, color = "grey10"
    ),
    legend.text = element_text(
      size = 10, color = "grey10"
    ),
    panel.grid.major = element_line(
      color = "white"
    ),
    panel.grid.minor = element_line(
      color = "white"
    ),
    plot.background = element_rect(
      fill = "white", color = NA
    ),
    legend.background = element_rect(
      fill = "white", color = NA
    ),
    panel.border = element_rect(
      fill = NA, color = "white"
    ),
    plot.margin = unit(
      c(
        t = 0, r = 0,
        b = 0, l = 0
      ), "lines"
    )
  ) + 
  labs(
    title = "Niedersachsen 2020 Forest Height Map",
    caption = "Datathon 2024 - Boineelo Moyo - Thunen-Institut"
  ) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.caption = element_text(hjust = 0.5)
  )

# 8. RENDER SCENE
#----------------

h <- nrow(forest_height_ni)
w <- ncol(forest_height_ni)

rayshader::plot_gg(
  ggobj = p,
  width = w / 1000,
  height = h / 1000,
  scale = 90,
  solid = F,
  soliddepth = 0,
  shadow = T,
  shadow_intensity = .99,
  offset_edges = F,
  sunangle = 315,
  window.size = c(800, 800),
  zoom = .4,
  phi = 30,
  theta = -30,
  multicore = T
)

rayshader::render_camera(
  phi = 50,
  zoom = .7,
  theta = 45
)

# 9. RENDER OBJECT
#-----------------

rayshader::render_highquality(
  filename = "niedersachsen-forest-height-2020.png",
  preview = T,
  interactive = F,
  light = T,
  lightdirection = c(
    315, 310, 315, 310
  ),
  lightintensity = c(
    1000, 1500, 150, 100
  ),
  lightaltitude = c(
    15, 15, 80, 80
  ),
  ground_material = 
    rayrender::microfacet(
      roughness = .6
    ),
  width = 4000,
  height = 4000
)
