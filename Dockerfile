FROM opencpu/rstudio

# HACK: to support new rlang version - better specify versions properly in packages
# OpenCPU currently installs rlang 0.1.1, but the new version of the tidyverse relies on
# rlang 0.1.2. Since the OpenCPU user cannot uninstall these packages, we remove them
# hard as root and install the new rlang version as dependency when installing snrgo
RUN rm -r /usr/lib/R/library/rlang
RUN rm -r /usr/lib/opencpu/library/rlang

# Switch to user opencpu so that all packages are installed in user r library and not in the system r library
USER opencpu
# Install Devtools package
RUN Rscript -e "install.packages('devtools', repos='https://cran.rstudio.com/')"
# Install sonar backend packages
# Install SonarGO package
# https://stackoverflow.com/questions/34617306/r-package-with-cran-and-bioconductor-dependencies
# Installing BiocInstaller
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('BiocInstaller')"
# Set Repos to CRAN and Bioconductor and then install snrgo and it's dependencies
RUN Rscript -e "setRepositories(ind=c(1,2)); devtools::install_github('paulklemm/snrgo')"
# Install Sonar package
RUN Rscript -e "devtools::install_github('paulklemm/snr')"
# Switch back to root, otherwise the webserver doesn't work
USER root
# Change the OpenCPU config settings
RUN sed -i '/"timelimit.post": 90/c\    "timelimit.post": 1000,' /etc/opencpu/server.conf
