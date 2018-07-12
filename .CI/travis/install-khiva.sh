#!/bin/bash
# Copyright (c) 2018 Shapelets.io
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

if [["$INSTALL_KHIVA_METHOD" == "installer"]]; then
    if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
        if [ ! -e "installers/khiva-v0.1.0-OnlyCPU.pkg" ]; then
            wget https://github.com/shapelets/khiva/releases/download/v0.1.0/khiva-v0.1.0-OnlyCPU.pkg -O installers/khiva-v0.1.0-OnlyCPU.pkg
        fi

        sudo installer -pkg installers/khiva-v0.1.0-OnlyCPU.pkg -target /
    else
        if [ ! -e "installers/khiva-v0.1.0-ci.sh" ]; then
            wget https://github.com/shapelets/khiva/releases/download/v0.1.0/khiva-v0.1.0-ci.sh -O installers/khiva-v0.1.0-ci.sh
            chmod +x installers/khiva-v0.1.0-ci.sh
        fi

        sudo ./installers/khiva-v0.1.0-ci.sh --prefix=/usr/local --skip-license

        sudo ldconfig
    fi
else
    # GitHub method
    # Install cmake in Linux, it is already installed in osx
    if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
        # Check if the file already exists
        if [ ! -e "${TRAVIS_BUILD_DIR}/cmake/cmake-3.11.3-Linux-x86_64.sh" ]; then
            mkdir -p cmake && cd cmake
            wget https://cmake.org/files/v3.11/cmake-3.11.3-Linux-x86_64.sh
            cd ..
        fi
        # Install cmake
        mkdir cmakebin
        cp cmake/cmake-3.11.3-Linux-x86_64.sh cmakebin/cmake-3.11.3-Linux-x86_64.sh
        cd cmakebin
        chmod +x cmake-3.11.3-Linux-x86_64.sh
        sudo ./cmake-3.11.3-Linux-x86_64.sh --skip-license
        cd ..
    fi

     #Installing conan and dependencies
     if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
        sudo apt-get update -y
        sudo apt-get install -y python3 python3-pip
        sudo pip3 install conan
     else
        brew upgrade pyenv
        export PATH=$HOME/.pyenv/shims:$HOME/.pyenv/versions/${TRAVIS_PYTHON_VERSION}/bin:$PATH
        pyenv install 3.6.5 -s
        pyenv init -
        pyenv local 3.6.5

        # Installing conan
        sudo pip3 install --upgrade pip
        sudo pip3 install conan
     fi
     conan remote add -f conan-mpusz https://api.bintray.com/conan/mpusz/conan-mpusz

    # Cloning Github repo into khiva-library folder
    git clone https://github.com/shapelets/khiva.git ../khiva-library
    cd ../khiva-library
    mkdir -p build && cd build
    if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
        conan install .. -s compiler=apple-clang -s compiler.version=9.1 -s compiler.libcxx=libc++ --build missing
        cmake .. -DKHIVA_ONLY_CPU_BACKEND=ON -DKHIVA_BUILD_DOCUMENTATION=OFF -DKHIVA_BUILD_EXAMPLES=OFF -DKHIVA_BUILD_BENCHMARKS=OFF
        make install -j8
    else
        conan install .. --build missing
        ../../khiva-r/cmakebin/bin/cmake .. -DKHIVA_ENABLE_COVERAGE=ON -DKHIVA_BUILD_DOCUMENTATION=OFF -DKHIVA_BUILD_EXAMPLES=OFF -DKHIVA_BUILD_BENCHMARKS=OFF
        sudo make install -j8
        sudo ldconfig
    fi
    # Switching back to the khiva-r folder
    cd /home/travis/build/shapelets/khiva-r
fi
