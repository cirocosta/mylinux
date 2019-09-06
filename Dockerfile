FROM ubuntu:disco

        ADD ./install.sh /install.sh

        RUN /install.sh

        ENTRYPOINT [ "bash", "--login" ]
