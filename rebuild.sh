cd otp && \
./otp_build boot -a && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
./otp_build release -a $(pwd)/RELEASE && \
cd RELEASE && \
./Install -cross -minimal $(pwd)
