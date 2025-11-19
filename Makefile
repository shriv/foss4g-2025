GPKG_FILES = \
	data/nz-suburbs-and-localities.gpkg \
	data/urban-rural-2025-clipped.gpkg

$(GPKG_FILES): 
	unzip data/lds-nz-suburbs-and-localities-GPKG.zip nz-suburbs-and-localities.gpkg -d data/
	unzip data/statsnz-urban-rural-2025-clipped-GPKG.zip urban-rural-2025-clipped.gpkg -d data/

EAST_TAMAKI = data/outputs/merged_enriched_East\ Tāmaki.parquet \
	data/outputs/osm_blocks_enriched_East\ Tāmaki.parquet \
	data/outputs/osm_buildings_enriched_East\ Tāmaki.parquet \
	data/outputs/osm_streets_enriched_East\ Tāmaki.parquet \
	data/outputs/osm_tessellation_enriched_East\ Tāmaki.parquet \
	data/outputs/osm_percentiles_joined_East\ Tāmaki.parquet

$(EAST_TAMAKI): data/nz-suburbs-and-localities.gpkg
	mkdir -p data/outputs
	mkdir -p data/buildings
	mkdir -p data/streets
	uv run python/main.py \
		-f "data/nz-suburbs-and-localities.gpkg" \
		-a "East Tāmaki"

east_tamaki: $(EAST_TAMAKI)

PONSONBY = data/outputs/merged_enriched_Ponsonby.parquet \
	data/outputs/osm_blocks_enriched_Ponsonby.parquet \
	data/outputs/osm_buildings_enriched_Ponsonby.parquet \
	data/outputs/osm_streets_enriched_Ponsonby.parquet \
	data/outputs/osm_tessellation_enriched_Ponsonby.parquet

$(PONSONBY): $(GPKG_FILES)
	mkdir -p data/outputs
	mkdir -p data/buildings
	mkdir -p data/streets
	uv run python/main.py \
		-f "data/nz-suburbs-and-localities.gpkg" \
		-a "Ponsonby"

ponsonby: $(PONSONBY)

GREY_LYNN = data/outputs/merged_enriched_Grey\ Lynn.parquet \
	data/outputs/osm_blocks_enriched_Grey\ Lynn.parquet \
	data/outputs/osm_buildings_enriched_Grey\ Lynn.parquet \
	data/outputs/osm_streets_enriched_Grey\ Lynn.parquet \
	data/outputs/osm_tessellation_enriched_Grey\ Lynn.parquet

$(GREY_LYNN): $(GPKG_FILES)
	mkdir -p data/outputs
	mkdir -p data/buildings
	mkdir -p data/streets
	uv run python/main.py \
		-f "data/nz-suburbs-and-localities.gpkg" \
		-a "Grey Lynn"

grey_lynn: $(GREY_LYNN)

WELLINGTON = data/outputs/merged_enriched_Wellington.parquet \
	data/outputs/osm_blocks_enriched_Wellington.parquet \
	data/outputs/osm_buildings_enriched_Wellington.parquet \
	data/outputs/osm_streets_enriched_Wellington.parquet \
	data/outputs/osm_tessellation_enriched_Wellington.parquet

$(WELLINGTON): $(GPKG_FILES)
	mkdir -p data/outputs
	mkdir -p data/buildings
	mkdir -p data/streets
	uv run python/main.py \
		-f "data/urban-rural-2025-clipped.gpkg" \
		-a "Wellington"

wellington: $(WELLINGTON)



AUCKLAND = data/outputs/merged_enriched_Auckland.parquet \
	data/outputs/osm_blocks_enriched_Auckland.parquet \
	data/outputs/osm_buildings_enriched_Auckland.parquet \
	data/outputs/osm_streets_enriched_Auckland.parquet \
	data/outputs/osm_tessellation_enriched_Auckland.parquet

$(AUCKLAND): $(GPKG_FILES)
	mkdir -p data/outputs
	mkdir -p data/buildings
	mkdir -p data/streets
	uv run python/main.py \
		-f "data/urban-rural-2025-clipped.gpkg" \
		-a "Auckland"

auckland: $(AUCKLAND)

setup: $(WELLINGTON) $(AUCKLAND) $(GREY_LYNN) $(PONSONBY) $(EAST_TAMAKI)
	uv sync && \
	Rscript -e "renv::activate()" && \
	Rscript -e "renv::restore()"

render: 
	source .venv/bin/activate && \
	Rscript -e "renv::activate()" && \
	quarto render quarto/


clean: 
	rm -rf data/outputs data/buildings data/streets quarto/_site quarto/.quarto|| true