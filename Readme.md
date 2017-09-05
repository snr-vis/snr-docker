# Build Container and Push to DockerHub

```bash
make
```

# Run Container

OpenCPU is run as Docker container. In order to provide it with the required data, you have to pass it the following folders:

- `data` contains the differential gene expression data

Inside the `OpenCPU` docker image, a user called opencpu requires read and write access to the folders listed above. The opencpu user in docker image is user group `www-data`, therefore files mounted via `-v` have to be part of `www-data` group and should be group-writeable (e.g. 755).

Example call:

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/data:/home/opencpu/sonar/data \
    --name opencpu_rstudio \
    snr
```

# Run Container Dev Mode

To allow easy changes of the `R` packages they can also be mounted as external volumes:

*Macbook Paths:*

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/data:/home/opencpu/sonar/data \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/sona-R:/home/opencpu/sonar/sonaR \
    --name opencpu_rstudio \
    snr
```

*Aligner Paths:*

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /opt/sonar/data:/home/opencpu/sonar/data \
    -v /opt/sonar/sona-R:/home/opencpu/sonar/sonaR \
    --name opencpu_rstudio \
    snr
```

Edit the package using RStudio:

- [`localhost:8004/rstudio`](localhost:8004/rstudio)
- User/PW: `opencpu`/`opencpu`
