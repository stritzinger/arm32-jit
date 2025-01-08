cd otp
./otp_build update_configure --no-commit && \
./otp_build configure --xcomp-conf=xcomp/erl-xcomp-arm-linux-custom.conf && \
./otp_build boot -a && \
rm -rf RELEASE/* && \
mkdir -p RELEASE && \
./otp_build release -a $(pwd)/RELEASE && \
cd RELEASE && \
./Install -cross -minimal $(pwd)

# extra steps if dinamic linking breaks
# ln -s /usr/arm-linux-gnueabi/lib/ld-linux.so.3 /lib/ld-linux.so.3
# ln -s /usr/arm-linux-gnueabi/lib/libc.so.6 /lib/libc.so.6
# ln -s /usr/arm-linux-gnueabi/lib/libm.so.6 /lib/libm.so.6
