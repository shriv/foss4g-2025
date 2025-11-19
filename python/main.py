
import momepy_metrics as mm
import argparse

def init_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        usage="%(prog)s [FILE] [AREA]...",
        description="Generate momepy morphometrics"
    )
    parser.add_argument(
        "-f", "--file", action="store"
    )
    parser.add_argument(
        "-a", "--area", action="store"
    )
    return parser


parser = init_argparse()
args = parser.parse_args()

geometry_filename = args.file
urban_area = args.area

buildings, \
streets, \
tessellation, \
blocks, \
merged, \
percentiles_joined = mm.generate_morphometrics(
    geometry_filename,
    urban_area)

tessellation.to_parquet(f"data/outputs/osm_tessellation_enriched_{urban_area}.parquet")
streets.to_parquet(f"data/outputs/osm_streets_enriched_{urban_area}.parquet")
buildings.to_parquet(f"data/outputs/osm_buildings_enriched_{urban_area}.parquet")
blocks.to_parquet(f"data/outputs/osm_blocks_enriched_{urban_area}.parquet")
merged.to_parquet(f"data/outputs/merged_enriched_{urban_area}.parquet")
percentiles_joined.to_parquet(f"data/outputs/percentiles_joined_{urban_area}.parquet")
