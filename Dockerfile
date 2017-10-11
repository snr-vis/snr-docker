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
################ SNR ###################################
########################################################

# Assign site-library to www-data group to make it writeable for opencpu user.
# This is required so we can hot-rebuild the `snr` and `snrgo` package
# from within the rstudio session.
RUN \
  chgrp -R www-data /usr/local/lib/R/site-library

# HACK: Create a commonly used folder for ensembl temp files.
RUN mkdir -p /usr/local/var/ensembl && \
  chgrp -R www-data /usr/local/var/ensembl && \
	chmod -R 777 /usr/local/var/ensembl

# Install SonarGO package
# Installing BiocInstaller - https://stackoverflow.com/questions/34617306/r-package-with-cran-and-bioconductor-dependencies
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('BiocInstaller')"
# Set repos to CRAN and Bioconductor and then install `snrgo` and it's dependencies
RUN Rscript -e "setRepositories(ind=c(1,2)); devtools::install_github('paulklemm/snrgo')"
# Install Sonar package
RUN Rscript -e "devtools::install_github('paulklemm/snr')"
# HACK: OpenCPU and RStudio already install some packages that are also requirements
# for the `snr` and `snrgo` package. When `snr` and `snrgo` rely on never versions this
# causes problems. Therefore we will remove the duplicated packages and only keep the ones 
# in the default library `/usr/local/lib/R/site-library`.
# Uninstall all duplicated packages - https://stat.ethz.ch/pipermail/r-help/2007-December/149097.html
RUN Rscript -e "remove.packages(installed.packages()[duplicated(rownames(installed.packages())),1], lib=.libPaths()[.libPaths() != .Library])"
# Change the OpenCPU config settings
RUN sed -i '/"timelimit.post": 90/c\    "timelimit.post": 1000,' /etc/opencpu/server.conf

# Add the CRON-Job to purge session files older than one hour
# From https://github.com/opencpu/opencpu-server/blob/master/opencpu-server/cron.d/opencpu
RUN echo '*/10 * * * * www-data /usr/lib/opencpu/scripts/cleanocpu.sh' > /etc/cron.d/opencpu

# Start rstudio server and opencpu server. Server is started now because otherwise newly installed package will already be loaded.
CMD /usr/lib/rstudio-server/bin/rserver && apachectl -DFOREGROUND
