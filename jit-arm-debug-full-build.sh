cd otp && \
./otp_build update_configure --no-commit && \
./otp_build configure --xcomp-conf=xcomp/erl-xcomp-arm-linux-debug-custom.conf && \
./otp_build boot -a && \
make TYPE=debug -j"$(nproc)" all && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
make TYPE=debug RELEASE_ROOT=$(pwd)/RELEASE release && \
cd RELEASE && \
./Install -cross -minimal $(pwd)
