cd otp
./otp_build update_configure --no-commit && \
./otp_build configure --xcomp-conf=xcomp/erl-xcomp-arm-linux-custom.conf && \
./otp_build boot -a && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
./otp_build release -a $(pwd)/RELEASE && \
cd RELEASE && \
./Install -cross -minimal $(pwd)
