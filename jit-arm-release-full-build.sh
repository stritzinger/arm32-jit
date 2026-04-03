cd otp && \
./otp_build update_configure --no-commit && \
./otp_build configure --xcomp-conf=xcomp/erl-xcomp-arm-linux-release-custom.conf && \
./otp_build boot -a && \
make -j"$(nproc)" all && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
make RELEASE_ROOT=$(pwd)/RELEASE release && \
cd RELEASE && \
./Install -cross -minimal $(pwd)
