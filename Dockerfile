FROM opencpu/rstudio

# HACK: OpenCPU and RStudio already install some packages that are also requirements
# for the `snr` and `snrgo` package. Since these packages are installed as root, the opencpu
# user cannot change them. If `snrgo` or `snr` rely on newer versions of these packages,
# the installation process fails. Therefore the libraries are now switched to the 
# www-data, which the opencpu and www-data user are part of and are set to 775
# Later after installing all packages we will remove all duplicated packages and this
# should fix incompatibility issues
RUN chgrp -R www-data /usr/lib/R/library && chmod -R 775 /usr/lib/R/library
RUN chgrp -R www-data /usr/lib/opencpu/library && chmod -R 775 /usr/lib/opencpu/library

# HACK: Create a commonly used folder for ensembl temp files.
RUN mkdir -p /usr/local/var/ensembl
RUN chgrp -R www-data /usr/local/var/ensembl
RUN chmod -R 777 /usr/local/var/ensembl

# Switch to user opencpu so that all packages are installed in user r library and not in the system r library
USER opencpu
# Install `devtools` package
RUN Rscript -e "install.packages('devtools', repos='https://cran.rstudio.com/')"
# Install sonar backend packages
# Install SonarGO package
# https://stackoverflow.com/questions/34617306/r-package-with-cran-and-bioconductor-dependencies
# Installing BiocInstaller
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('BiocInstaller')"
# Set repos to CRAN and Bioconductor and then install `snrgo` and it's dependencies
RUN Rscript -e "setRepositories(ind=c(1,2)); devtools::install_github('paulklemm/snrgo')"
# Install Sonar package
RUN Rscript -e "devtools::install_github('paulklemm/snr')"
# Uninstall all duplicated packages - https://stat.ethz.ch/pipermail/r-help/2007-December/149097.html
RUN Rscript -e "remove.packages(installed.packages()[duplicated(rownames(installed.packages())),1], lib=.libPaths()[.libPaths() != '/usr/local/lib/opencpu/site-library'])"
# Switch back to root, otherwise the web-server doesn't work
USER root
# Change the OpenCPU config settings
RUN sed -i '/"timelimit.post": 90/c\    "timelimit.post": 1000,' /etc/opencpu/server.conf
