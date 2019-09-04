FROM ubuntu:bionic

        ADD ./install.sh /install.sh

        RUN /install.sh

        ENTRYPOINT [ "bash", "--login" ]
