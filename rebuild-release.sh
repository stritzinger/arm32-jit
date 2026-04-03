cd otp && \
make -j"$(nproc)" all && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
make RELEASE_ROOT=$(pwd)/RELEASE release && \
cd RELEASE && \
./Install -cross -minimal $(pwd)
