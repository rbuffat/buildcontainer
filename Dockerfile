ARG BASE_IMAGE=python:3.9.1-buster

FROM $BASE_IMAGE as builder

RUN apt-get update && apt-get install -y libatlas-base-dev libcurl4-openssl-dev libgeos-dev libfreexl-dev libzstd-dev libspatialite-dev sqlite3

# Install proj
ARG PROJ_VERSION
RUN mkdir proj \
    && cd proj \
    && wget -q https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz \
    && tar -xzf proj-${PROJ_VERSION}.tar.gz \
    && rm proj-${PROJ_VERSION}.tar.gz \
    && cd proj-${PROJ_VERSION} \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) -s \
    && make install \
    && cd ../.. \
    && rm -rf proj

# Install FileGDB
RUN mkdir filegdb \
    && cd filegdb \ 
    && wget -q https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.1/FileGDB_API_1_5_1-64gcc51.tar.gz \
    && tar -xzf FileGDB_API_1_5_1-64gcc51.tar.gz --strip=1 FileGDB_API-64gcc51 \
    && rm FileGDB_API_1_5_1-64gcc51.tar.gz \
    && rm -rf samples \
    && rm -rf doc \
    && cd ..  \
    && mv filegdb /usr/local

# Install GDAL
# TODO gdalver=$(expr "$GDALVERSION" : '\([0-9]*.[0-9]*.[0-9]*\)') to strip RC versions for http://download.osgeo.org/gdal/${GDAL_VERSION}
ARG GDAL_VERSION
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/filegdb/lib:$LD_LIBRARY_PATH"
ENV GDAL_DATA=/usr/local/share/gdal
ENV PROJ_LIB=/usr/local/share/proj
RUN mkdir gdal \
    && cd gdal \
    && echo "LD $LD_LIBRARY_PATH" \
    && wget -q http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
    && tar -xzf gdal-${GDAL_VERSION}.tar.gz \
    && cd gdal-${GDAL_VERSION} \
    && ./configure --prefix=/usr/local --without-python --with-fgdb=/usr/local/filegdb --with-proj=/usr/local/ --with-sqlite3 --with-geos --with-expat \
    && make -j$(nproc) -s \
    && make install \
    && cd ../.. \
    && rm -rf gdal

ENV PATH="/usr/local/bin:$PATH"
