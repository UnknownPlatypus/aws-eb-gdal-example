# This script is used to build GDAL and GEOS libraries that are not directly available
# using yum and amazon linux repos. He should be executed manually on an EC2 instance.
# The resulting binaries are stored on s3://##YOUR_PRIVATE_S3_BUCKET##/builds/

# Check https://docs.djangoproject.com/en/dev/ref/contrib/gis/install/geolibs/ for supported versions
# for your specific django version.
GEOS_VERSION=3.6.4 # https://libgeos.org/usage/download/
GDAL_VERSION=2.4.4 # http://download.osgeo.org/gdal/ 
PROJ_VERSION=5.2.0 # http://download.osgeo.org/proj/

sudo yum -y update
sudo yum-config-manager --enable epel
sudo yum -y install make automake gcc gcc-c++ libcurl-devel geos-devel

# Compilation work for geos.
mkdir -p "/tmp/geos-${GEOS_VERSION}-build"
cd "/tmp/geos-${GEOS_VERSION}-build"
curl -o "geos-${GEOS_VERSION}.tar.bz2" \
    "http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2" \
    && bunzip2 "geos-${GEOS_VERSION}.tar.bz2" \
    && tar xvf "geos-${GEOS_VERSION}.tar"
cd "/tmp/geos-${GEOS_VERSION}-build/geos-${GEOS_VERSION}"
./configure --prefix=/usr/local/geos

# Make in parallel with 2x the number of processors.
make -j $(( 2 * $(cat /proc/cpuinfo | egrep ^processor | wc -l) )) \
 && sudo make install \
 && sudo ldconfig

# Compilation work for proj (mandatory to build gdal).
mkdir -p "/tmp/proj-${PROJ_VERSION}-build"
cd "/tmp/proj-${PROJ_VERSION}-build"
curl -o "proj-${PROJ_VERSION}.tar.gz" \
    "http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz" \
    && tar xfz "proj-${PROJ_VERSION}.tar.gz"
cd "/tmp/proj-${PROJ_VERSION}-build/proj-${PROJ_VERSION}"
./configure --prefix=/usr/local/proj

# Make in parallel with 2x the number of processors.
make -j $(( 2 * $(cat /proc/cpuinfo | egrep ^processor | wc -l) )) \
 && sudo make install \
 && sudo ldconfig

# Compilation work for gdal.
mkdir -p "/tmp/gdal-${GDAL_VERSION}-build"
cd "/tmp/gdal-${GDAL_VERSION}-build"
curl -o "gdal-${GDAL_VERSION}.tar.gz" \
    "http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz" \
    && tar xfz "gdal-${GDAL_VERSION}.tar.gz"
cd "/tmp/gdal-${GDAL_VERSION}-build/gdal-${GDAL_VERSION}"
./configure --prefix=/usr/local/gdal \
    --with-proj=/usr/local/proj \
    --without-python

# Make in parallel with 2x the number of processors.
make -j $(( 2 * $(cat /proc/cpuinfo | egrep ^processor | wc -l) )) \
 && sudo make install \
 && sudo ldconfig


# Bundle resources
cd /usr/local/geos
tar zcvf "/tmp/geos-${GEOS_VERSION}.tar.gz" *

cd /usr/local/proj
tar zcvf "/tmp/proj-${PROJ_VERSION}.tar.gz" *

cd /usr/local/gdal
tar zcvf "/tmp/gdal-${GDAL_VERSION}.tar.gz" *

# Move them to public S3 folder
cd /tmp/
aws s3 cp "/tmp/geos-${GEOS_VERSION}.tar.gz" s3://##YOUR_PRIVATE_S3_BUCKET##/builds/
aws s3 cp "/tmp/proj-${PROJ_VERSION}.tar.gz" s3://##YOUR_PRIVATE_S3_BUCKET##/builds/
aws s3 cp "/tmp/gdal-${GDAL_VERSION}.tar.gz" s3://##YOUR_PRIVATE_S3_BUCKET##/builds/
