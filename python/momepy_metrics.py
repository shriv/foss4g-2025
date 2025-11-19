import momepy
import geopandas as gpd
import pandas as pd
import osmnx as ox
import libpysal
import os

def generate_morphometrics(
    geometry_filename = "data/lds-nz-suburbs-and-localities-GPKG/nz-suburbs-and-localities.gpkg", 
    urban_area = "East Tāmaki"
    ):

    local_crs = 2193

    # Calculate bounding box based on urban/rural geometries or suburba
    urban_areas_df = gpd.read_file(geometry_filename)

    if "urban" in geometry_filename:
        urban_area_geom = urban_areas_df.query('UR2025_V1_00_NAME in @urban_area')
    else:    
        urban_area_geom = urban_areas_df.query('name in @urban_area')

    bbox = urban_area_geom.bounds.values[0]

    # Save raw data filenames
    buildings_file = f"data/buildings/osm_buildings_{urban_area}.parquet"
    streets_file = f"data/streets/osm_streets_{urban_area}.parquet"

    # Load raw data from saved file or extract from OSM
    if os.path.exists(buildings_file):
        buildings = gpd.read_parquet(buildings_file)

    else:
        buildings = ox.features_from_bbox(
            bbox,
            tags={"building": True})
        buildings = (buildings[buildings.geom_type == "Polygon"]
            .reset_index(drop=True)
            .drop_duplicates()
            .to_crs(local_crs)
        )

        # Two-step process for removing duplicates
        # https://github.com/geopandas/geopandas/issues/3098#issuecomment-1839326589
        # Need this as well to remove pesky geometry duplicates
        buildings["geometry"] = buildings.normalize()
        buildings.drop_duplicates()

        # https://github.com/pysal/momepy/issues/721#issuecomment-3442038750
        buildings = buildings[buildings.geometry.duplicated() == False]
        
        # Only keep geometry
        buildings = buildings.explode()[['geometry']]

        # Save
        buildings.to_parquet(buildings_file)

    if os.path.exists(streets_file):
        streets = gpd.read_parquet(streets_file)

    else:
        osm_graph = ox.graph_from_bbox(
            bbox,
            network_type="drive"
            )

        osm_graph = ox.projection.project_graph(osm_graph, to_crs=local_crs)
        streets = ox.graph_to_gdfs(
            ox.convert.to_undirected(osm_graph),
            nodes=False,
            edges=True,
            node_geometry=False,
            fill_edge_geometry=True,
        ).reset_index(drop=True)

        streets = momepy.remove_false_nodes(streets)
        streets = streets[["geometry"]]
        streets.to_parquet(streets_file)

    ## Tesselation
    limit = momepy.buffered_limit(buildings, "adaptive")
    tessellation = momepy.morphological_tessellation(buildings, segment = 4.0, clip=limit)
    collapsed, _ = momepy.verify_tessellation(tessellation, buildings)

    buildings = buildings.drop(collapsed)
    limit = momepy.buffered_limit(buildings, "adaptive")
    tessellation = momepy.morphological_tessellation(buildings, segment = 4.0, clip=limit)

    # check
    tessellation.shape[0] == buildings.shape[0]

    # associate streets
    buildings["street_index"] = momepy.get_nearest_street(
        buildings, streets, max_distance=100
    )

    tessellation["street_index"] = buildings["street_index"]

    # pre-req
    queen_1 = libpysal.graph.Graph.build_contiguity(tessellation, rook=False)
    queen_3 = queen_1.higher_order(3)
    buildings_q1 = libpysal.graph.Graph.build_contiguity(buildings, rook=False)

    # dimensions
    buildings["building_area"] = buildings.area
    buildings["eri"] = momepy.equivalent_rectangular_index(buildings)
    buildings["elongation"] = momepy.elongation(buildings)
    buildings["shared_walls"] = momepy.shared_walls(buildings) / buildings.length
    buildings["neighbor_distance"] = momepy.neighbor_distance(buildings, queen_1)
    buildings["interbuilding_distance"] = momepy.mean_interbuilding_distance(buildings, queen_1, queen_3)
    buildings["adjacency"] = momepy.building_adjacency(buildings_q1, queen_3)

    tessellation["tess_area"] = tessellation.area
    tessellation["convexity"] = momepy.convexity(tessellation)
    tessellation["neighbors"] = momepy.neighbors(tessellation, queen_1, weighted=True)
    tessellation["covered_area"] = queen_1.describe(tessellation.area)["sum"]
    tessellation["car"] = buildings.area / tessellation.area

    streets["length"] = streets.length
    streets["linearity"] = momepy.linearity(streets)
    profile = momepy.street_profile(streets, buildings)
    streets[profile.columns] = profile


    graph = momepy.gdf_to_nx(streets)
    graph = momepy.node_degree(graph)
    graph = momepy.closeness_centrality(graph, radius=400, distance="mm_len")
    graph = momepy.meshedness(graph, radius=400, distance="mm_len")
    nodes, edges = momepy.nx_to_gdf(graph)

    buildings["edge_index"] = momepy.get_nearest_street(buildings, edges)
    buildings["node_index"] = momepy.get_nearest_node(
        buildings, nodes, edges, buildings["edge_index"]
    )


    tessellation[buildings.columns.drop(["geometry", "street_index"])] = (
        buildings.drop(columns=["geometry", "street_index"])
    )

    # Blocks
    blocks, tessellation_id = momepy.generate_blocks(
        tessellation, streets, buildings
    )

    # buildings["bID"] = tessellation_id[tessellation_id.index >= 0]
    # tessellation["bID"] = tessellation_id

    # Merged
    merged = tessellation.merge(
        edges.drop(columns="geometry"),
        left_on="edge_index",
        right_index=True,
        how="left",
    )
    merged = merged.merge(
        nodes.drop(columns="geometry"),
        left_on="node_index",
        right_index=True,
        how="left",
    )


    # Extending morphometrics with neighbourhood distributions
    percentiles = []
    for column in merged.columns.drop(
        [
            "street_index",
            "node_index",
            "edge_index",
            "nodeID",
            "mm_len",
            "node_start",
            "node_end",
            "geometry",
        ]
    ):
        perc = momepy.percentile(merged[column], queen_3)
        perc.columns = [f"{column}_" + str(x) for x in perc.columns]
        percentiles.append(perc)

    percentiles_joined = pd.concat(percentiles, axis=1)
    percentiles_joined.head()

    return(
        buildings, 
        streets, 
        tessellation, 
        blocks, 
        merged, 
        percentiles_joined)

