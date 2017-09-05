FROM opencpu/rstudio

# Install Devtools package
RUN Rscript -e "install.packages('devtools', repos='https://cran.rstudio.com/')"
# Install sonar backend package
RUN Rscript -e "devtools::install_github('paulklemm/snr')"
