
library(ggplot2)
library(sf)
library(dplyr)

generate_clusters_plots <- function(
  bldg_sub_df, akl_ns, cluster_num
  ){
    p <- ggplot() + 
        geom_sf(data = akl_ns, fill = NA, lwd=0.5) +
        geom_sf(data = bldg_sub_df |> filter(cluster==cluster_num), aes(fill = cluster, colour=cluster), show.legend = TRUE)  + 
        coord_sf(crs = st_crs(2193)) +
        scale_fill_discrete(drop=FALSE) +
        scale_colour_discrete(drop=FALSE) +
        theme_void() +
        labs(title = paste("Cluster", cluster_num)) + 
        theme(plot.title = element_text(hjust = 0.5)) 

    return(p)
}

generate_suburb_clusters_plots <- function(
  bldg_sub_df, suburb_name
  ){
    p <- ggplot() + 
        geom_sf(data = bldg_sub_df |> filter(name==suburb_name), aes(fill = cluster, colour=cluster), show.legend = TRUE)  + 
        coord_sf(crs = st_crs(2193)) +
        scale_fill_discrete(drop=FALSE) +
        scale_colour_discrete(drop=FALSE) +
        theme_void() +
        labs(title = suburb_name) + 
        theme(plot.title = element_text(hjust = 0.5)) 

    return(p)
}
