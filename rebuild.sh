cd otp && \
make TYPE=debug -j"$(nproc)" all && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
make TYPE=debug RELEASE_ROOT=$(pwd)/RELEASE release && \
cd RELEASE && \
./Install -cross -minimal $(pwd)
