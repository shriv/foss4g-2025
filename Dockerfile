FROM --platform=linux/amd64 rocker/r-ver:4.3.1

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------------------
# 1. Install Linux deps
# ----------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    wget \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    software-properties-common

# ----------------------------------------------------------------------
# 2. Install Python 3.12.2 via Deadsnakes
# ----------------------------------------------------------------------
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install -y \
    python3.12 python3.12-dev python3.12-venv

# Make python3.12 the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# ----------------------------------------------------------------------
# 3. Install uv
# ----------------------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# ----------------------------------------------------------------------
# 4. Copy R project + env files
# ----------------------------------------------------------------------
WORKDIR /home/rstudio

RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv.lock renv.lock
COPY uv.lock uv.lock

# Change renv cache location (optional but recommended)
RUN mkdir renv/.cache
ENV RENV_PATHS_CACHE renv/.cache

# ----------------------------------------------------------------------
# 5. Install R packages
# ----------------------------------------------------------------------
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e 'renv::restore()'

# ----------------------------------------------------------------------
# 5. Install Python packages
# ----------------------------------------------------------------------
RUN uv sync
