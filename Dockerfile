FROM ruby:latest

MAINTAINER "Andrius Kairiukstis" <k@andrius.mobi>

# LABEL io.k8s.description="Headless VNC Container with IceWM window manager, firefox and chromium" \
#       io.k8s.display-name="Headless VNC Container based on Ubuntu" \
#       io.openshift.expose-services="6901:http,5901:xvnc" \
#       io.openshift.tags="vnc, ruby, debian, icewm" \
#       io.openshift.non-scalable=true

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY :1
ENV VNC_PORT 5901
ENV NO_VNC_PORT 6901
EXPOSE $VNC_PORT $NO_VNC_PORT

ENV HOME /headless
ENV STARTUPDIR /dockerstartup
WORKDIR $HOME

### Envrionment config
ENV DEBIAN_FRONTEND noninteractive
ENV NO_VNC_HOME $HOME/noVNC
ENV VNC_COL_DEPTH 24
ENV VNC_RESOLUTION 1280x1024
ENV VNC_PW vncpassword

### Add all install scripts for further steps
ENV INST_SCRIPTS $HOME/install-scripts
ADD ./install-scripts $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
# RUN $INST_SCRIPTS/tools.sh
RUN apt-get update \
\
&& echo "Installing utils" \
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     apt-utils \
     net-tools \
     wget \
     curl \
     sudo \
     tmux \
     mc \
     vim-nox \
     htop \
\
&& echo "Installing IceWM and xorg" \
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     icewm \
     supervisor \
     terminator \
     x11-xserver-utils \
     xfonts-base \
     xauth \
     xinit \
     xserver-xorg-video-dummy \
\
&& apt-get purge -yqq pm-utils xscreensaver* \
\
&& echo "Installing TigerVNC" \
&& wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C / \
\
&& echo "Installing noVNC" \
&& mkdir -p $NO_VNC_HOME/utils/websockify \
&& wget -qO- https://github.com/kanaka/noVNC/archive/v0.6.2.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME \
&& wget -qO- https://github.com/kanaka/websockify/archive/v0.8.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify \
&& chmod +x -v $NO_VNC_HOME/utils/*.sh \
&& ln -s $NO_VNC_HOME/vnc_auto.html $NO_VNC_HOME/index.html \
\
&& echo "Installing Firefox" \
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     firefox-esr=45* \
&& apt-mark hold firefox \
\
&& echo "Installing Chromium browser" \
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     chromium \
     chromium-inspector \
     chromium-l10n \
&& ln -s /usr/bin/chromium-browser /usr/bin/google-chrome \
&& echo "CHROMIUM_FLAGS='--no-sandbox --start-maximized --user-data-dir --enable-remote-extensions'" > $HOME/.chromium-browser.init \
\
&& echo "Cleaning system" \
&& apt-get clean all && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man* /tmp/* /var/tmp/*

### Install IceWM UI
ADD ./icewm/ $HOME/

# ### configure startup
# RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./startup-scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

EXPOSE 5901
EXPOSE 6901

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--tail-log"]
