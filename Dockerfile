FROM opencpu/rstudio

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
sed -i '/"timelimit.post": 90/c\    "timelimit.post": 1000,' /etc/opencpu/server.conf
