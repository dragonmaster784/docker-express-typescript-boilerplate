FROM node:14.17.1 as base

LABEL MAINTAINER="Ryan de Kwaadsteniet <ryan@maholla.com>"

ARG OPENCV_VERSION=4.1.1

# Add package file
COPY package*.json ./

# Install deps
RUN npm i

# Copy source
COPY src ./src
COPY tsconfig.json ./tsconfig.json
COPY openapi.json ./openapi.json

# Build dist
RUN npm run build

# General packages
RUN apt-get update -q
RUN apt-get install -qy \
    build-essential cmake \
    pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev

# Install OpenCV
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
    && wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
    && unzip opencv.zip && unzip opencv_contrib.zip \
    && mv opencv-${OPENCV_VERSION} opencv && mv opencv_contrib-${OPENCV_VERSION} opencv_contrib \
    && cd opencv \
    && mkdir build && cd build \
    && cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D PYTHON_EXECUTABLE=$(which python3.9) \
    -D PYTHON_INCLUDE_DIR=$(python3.9 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -D PYTHON_PACKAGES_PATH=$(python3.9 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
    .. \
    && make install 

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Start production image build
FROM gcr.io/distroless/nodejs:14

# Copy node modules and build directory
COPY --from=base ./node_modules ./node_modules
COPY --from=base /dist /dist

# Copy static files
COPY src/public dist/src/public

# Expose port 3000
EXPOSE 3000
CMD ["dist/src/server.js"]
