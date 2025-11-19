# Exploring urban form in New Zealand
This repo is the companion to the FOSS4G 2025 talk of the same title. There is an explanatory web-book rendered at https://shriv.github.io/foss4g-2025/. 

To render the Quarto web-book, you just need to run `make setup` to get the data processed and `make render` to generate a local version of the Quarto web-book. Note, this should work on unix operating systems like MacOS and Linux. There is a `Dockerfile` as well for running the code inside Docker. If there are any problems, please open an issue. 

The code behind the web-book largely mostly Python but also uses R for the spatial visualisations. The project uses `uv` to manage the Python dependencies and `renv` to manage R dependencies. 

Note the clustering algorithms require a reasonable amount of RAM - it runs okay on an M2 Macbook Pro with 16 GB RAM. If the code fails to run (especially the Auckland file) please run it on a larger machine! 