# From https://github.com/opencpu/opencpu-server/blob/master/docker/base/Dockerfile

# Use builds from launchpad
FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get update && \
  apt-get -y dist-upgrade && \
  apt-get install -y software-properties-common && \
  add-apt-repository -y ppa:opencpu/opencpu-2.0 && \
  apt-get update && \
  apt-get install -y opencpu-server

# Prints apache logs to stdout
RUN \
  ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
  ln -sf /proc/self/fd/1 /var/log/apache2/error.log && \
  ln -sf /proc/self/fd/1 /var/log/opencpu/apache_access.log && \
  ln -sf /proc/self/fd/1 /var/log/opencpu/apache_error.log

# Set opencpu password so that we can login
RUN \
  echo "opencpu:opencpu" | chpasswd

# Apache ports
EXPOSE 80
EXPOSE 443
EXPOSE 8004

# From https://github.com/opencpu/opencpu-server/blob/master/docker/rstudio/Dockerfile

# Install development tools
RUN \
  apt-get install -y rstudio-server r-base-dev sudo curl git libcurl4-openssl-dev libssl-dev libxml2-dev libssh2-1-dev

########################################################
################ SNR-Opencpu ###########################
########################################################

# Install additional Ubuntu packages
RUN \
  apt-get install nano && \
  apt-get install --assume-yes rsyslog

# Run Cron with maximum logging for debugging purposes
# See https://stackoverflow.com/questions/32872764/cron-job-not-running-inside-docker-container-on-ubuntu
RUN rsyslogd

# Assign site-library to www-data group to make it writeable for opencpu user.
# This is required so we can hot-rebuild the `snr` and `snrgo` package
# from within the rstudio session.
RUN \
  chgrp -R www-data /usr/local/lib/R/site-library

# HACK: Create a commonly used folder for ensembl temp files.
RUN mkdir -p /usr/local/var/ensembl && \
  chgrp -R www-data /usr/local/var/ensembl && \
  chmod -R 777 /usr/local/var/ensembl

# Install GIT LFS support to fetch the git repo of snr
# See https://github.com/git-lfs/git-lfs/blob/master/INSTALLING.md
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
  sudo apt-get install git-lfs

# Install SonarGO package
# Installing BiocInstaller - https://stackoverflow.com/questions/34617306/r-package-with-cran-and-bioconductor-dependencies
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('BiocInstaller')"
# Set repos to CRAN and Bioconductor and then install `snrgo` and it's dependencies
RUN Rscript -e "setRepositories(ind=c(1,2)); devtools::install_github('snr-vis/snrgo')"
# Install roxygen for debugging purposes
RUN Rscript -e "install.packages('roxygen2', repos='http://cran.rstudio.com/')"

# HACK: Download the Ensembl Metadata
RUN Rscript -e "library(sonaRGO); summary <- get_go_summary()"

# Install Sonar package
# Clone the SNR package and install from folder because `install_github` has problems with LFS
RUN cd ~/ && \
  git clone https://github.molgen.mpg.de/paulklemm/snR.git && \
  Rscript -e "devtools::install('~/snR')"

#RUN Rscript -e "devtools::install_github('paulklemm/snr')"
# HACK: OpenCPU and RStudio already install some packages that are also requirements
# for the `snr` and `snrgo` package. When `snr` and `snrgo` rely on never versions this
# causes problems. Therefore we will remove the duplicated packages and only keep the ones 
# in the default library `/usr/local/lib/R/site-library`.
# Uninstall all duplicated packages - https://stat.ethz.ch/pipermail/r-help/2007-December/149097.html
RUN Rscript -e "remove.packages(installed.packages()[duplicated(rownames(installed.packages())),1], lib=.libPaths()[.libPaths() != .Library])"
# Change the OpenCPU config settings
# Increase the Post timeout
# Increase the RAM limit per task - https://stackoverflow.com/questions/20282051/memory-limit-opencpu-r
# Preload the custom packages
RUN sed -i '/"timelimit.post": 90/c\    "timelimit.post": 1000,' /etc/opencpu/server.conf && \
  sed -i '/"rlimit.as": 4e9/c\    "rlimit.as": 4e14,' /etc/opencpu/server.conf && \
  sed -i '/"rlimit.fsize": 1e9/c\    "rlimit.fsize": 1e14,' /etc/opencpu/server.conf && \
  sed -i '/"preload": \["lattice"\]/c\    "preload": \["lattice", "ggplot2", "sonaR", "sonaRGO", "dplyr", "readr", "jsonlite", "devtools", "biomaRt"\]' /etc/opencpu/server.conf

# Change deletion cycle to two weeks - (60 * 24 * 7 * 2)
RUN sed -i 's/+60/+20160/g' /usr/lib/opencpu/scripts/cleanocpu.sh && sed -i 's/+1440/+20160/g' /usr/lib/opencpu/scripts/cleanocpu.sh
# Add the CRON-Job to purge session files older than one hour
# From https://github.com/opencpu/opencpu-server/blob/master/opencpu-server/cron.d/opencpu
RUN echo '*/10 * * * * root /usr/lib/opencpu/scripts/cleanocpu.sh' > /etc/cron.d/opencpu
# Debug statement for cronjob
# RUN echo 'date >> /home/opencpu/debug.log' >> /usr/lib/opencpu/scripts/cleanocpu.sh
# Give execution rights on the cron job
# https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container
RUN chmod 0644 /etc/cron.d/opencpu
# RUN crontab /etc/cron.d/opencpu

########################################################
################ SNR-Node ##############################
########################################################

# Install node
#RUN \
#  apt-get -y update && \
#  apt-get -y install nodejs && \
#  apt-get -y install npm && \
#  # node points to nodejs - https://stackoverflow.com/a/18130296/2274058
#  update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
# Install Node (from https://askubuntu.com/a/262663)
RUN cd /usr/local/src && \
  curl http://nodejs.org/dist/v9.8.0/node-v9.8.0.tar.gz -o node-v9.8.0.tar.gz && \
  tar -xvzf node-v9.8.0.tar.gz && \
  cd node-v9.8.0 && \
  ./configure && \
  make && \
  make install && \
  npm install -g pm2

RUN echo "Redownload this"
# Download node project
RUN cd /usr/src/ && git clone https://github.com/snr-vis/snr && \
  cd /usr/src/snr/ && \
  npm install && \
  cd /usr/src/snr/client && \
  npm install && \
  npm run build

# Install apache that puts of port :85/ on the front end and :85/api on the node server
# Apache file:
# 
# server {
#   listen 85;
# 
#   location / {
#     proxy_set_header X-Real-IP $remote_addr;
#     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#     proxy_set_header Host $http_host;
#     proxy_set_header X-NginX-Proxy true;
#     proxy_pass http://127.0.0.1:3000;
#     proxy_redirect off;
#     proxy_connect_timeout 36000s;
#     proxy_read_timeout 36000s;
#     proxy_send_timeout 36000s;
#     send_timeout 36000s;
#   }
#   location /api {
#     proxy_pass http://127.0.0.1:3099;
#     proxy_http_version 1.1;
#     proxy_set_header Upgrade $http_upgrade;
#     proxy_set_header Connection 'upgrade';
#     proxy_set_header Host $host;
#     proxy_cache_bypass $http_upgrade;
#     proxy_connect_timeout 36000s;
#     proxy_read_timeout 36000s;
#     proxy_send_timeout 36000s;
#     send_timeout 36000s;
#   }
# }
# https://paste.ngx.cc/b8dae11690610e98
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04#set-up-reverse-proxy-server
RUN apt-get install -y nginx && \
  echo "server {\n  listen 85;\n\n  location / {\n    proxy_set_header X-Real-IP \$remote_addr;\n    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n    proxy_set_header Host \$http_host;\n    proxy_set_header X-NginX-Proxy true;\n    proxy_pass http://127.0.0.1:3000;\n    proxy_redirect off;\n    proxy_connect_timeout 36000s;\n    proxy_read_timeout 36000s;\n    proxy_send_timeout 36000s;\n    send_timeout 36000s;\n  }\n  location /api {\n    proxy_pass http://127.0.0.1:3099;\n    proxy_http_version 1.1;\n    proxy_set_header Upgrade \$http_upgrade;\n    proxy_set_header Connection 'upgrade';\n    proxy_set_header Host \$host;\n    proxy_cache_bypass \$http_upgrade;\n    proxy_connect_timeout 36000s;\n    proxy_read_timeout 36000s;\n    proxy_send_timeout 36000s;\n    send_timeout 36000s;\n  }\n}" >> /etc/nginx/sites-enabled/snr && \
  rm /etc/nginx/sites-enabled/default

# Start cron, rstudio server and opencpu server.
# Server is started now because otherwise newly installed package will already be loaded.
# https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container
CMD service nginx start && pm2 serve /usr/src/snr/client/build 3000 && pm2 start /usr/src/snr/snr-node-server.json && cron && /usr/lib/rstudio-server/bin/rserver && apachectl -DFOREGROUND
