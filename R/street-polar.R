library(sfnetworks)
library(dplyr)
library(sf)
library(ggplot2)
library(arrow)
library(geoarrow)
library(here)

generate_polar_plot <- function(urban_area = "Auckland"){

  urban_area_filename =  paste0("osm_streets_", {{urban_area}}, ".parquet")

  edges = open_dataset(
      here("data", "streets", urban_area_filename)
    ) |> 
    st_as_sf() |> 
    st_transform(4326) |> 
    as_sfnetwork() |> 
    activate("edges") |> 
    mutate(
      azimuth = edge_azimuth(degrees = TRUE),
      length = edge_length() / 1000
    ) |> 
    st_drop_geometry()

  breaks <- seq(0, 360, length.out = 19)
  midpoints <- (head(breaks, -1) + tail(breaks, -1)) / 2

  agg_data <- edges |> 
    as.data.frame() |> 
    mutate(
      azimuth = as.numeric(azimuth),
      azimuth = if_else(azimuth < 0, azimuth + 360, azimuth)) |> 
    mutate(
      angle_bin = cut(
        azimuth, 
        breaks = breaks, 
        include.lowest = TRUE, 
        labels = midpoints) |> 
        as.character() |> 
        as.numeric()
      ) |> 
    group_by(angle_bin) |> 
    summarise(length = sum(as.numeric(length)))

  p <- ggplot(agg_data, aes(x = angle_bin, y = length)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black") +
    coord_polar(start = 0, direction = 1) + # Use polar coordinates
    labs(
      title = {{urban_area}},
      x = "Direction (degrees)",
      y = "Total Street Length (km)"
    ) +
    scale_x_continuous(
      breaks = seq(0, 360, 20)
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5)) 

  return(p)
}

