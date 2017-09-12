# Sonar OpenCPU Dockerfile

<!-- TOC -->

- [Sonar OpenCPU Dockerfile](#sonar-opencpu-dockerfile)
	- [TODO](#todo)
	- [Build Container and Push to DockerHub](#build-container-and-push-to-dockerhub)
	- [Run Container](#run-container)
	- [Run Container Dev Mode](#run-container-dev-mode)

<!-- /TOC -->

## TODO

Issues related to [SNR-GO](https://github.sf.mpg.de/pklemm/sonargo):

- [ ] Call `get_go_summary` for all important species of the current ensembl release on package compile
- [x] Increase opencpu response time to allow for `get_go_summary` to properly execute
- [ ] Fix common folder `/usr/local/var/ensembl` or make it the primary one - [https://github.sf.mpg.de/pklemm/sonargo/issues/2](https://github.sf.mpg.de/pklemm/sonargo/issues/2)
- [x] Fix `rlang` version hack by specifying proper dependencies in the snrgo and snr `R` package - [https://github.sf.mpg.de/pklemm/sonargo/issues/3](https://github.sf.mpg.de/pklemm/sonargo/issues/3)

## Build Container and Push to DockerHub

```bash
make
```

Developer build without pushing to DockerHub:

```bash
docker build --no-cache -t snr . && docker tag snr paulklemm/snr:latest
```

## Run Container

Pull the container:

```bash
docker pull paulklemm/snr
```

OpenCPU is run as Docker container. In order to provide it with the required data, you have to pass it the following folders:

- `data` contains the differential gene expression data

Inside the `OpenCPU` docker image, a user called opencpu requires read and write access to the folders listed above. The opencpu user in docker image is user group `www-data`, therefore files mounted via `-v` have to be part of `www-data` group and should be group-writeable (e.g. 755).

Example call:

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/data:/home/opencpu/sonar/data \
    --name opencpu_rstudio \
    paulklemm/snr
```

## Run Container Dev Mode

To allow easy changes of the `R` packages they can also be mounted as external volumes:

*Macbook Paths:*

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/data:/home/opencpu/sonar/data \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/sona-R:/home/opencpu/sonar/sonaR \
    --name opencpu_rstudio \
    paulklemm/snr
```

*Aligner Paths:*

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /opt/sonar/data:/home/opencpu/sonar/data \
    -v /opt/sonar/sona-R:/home/opencpu/sonar/sonaR \
    --name opencpu_rstudio \
    paulklemm/snr
```

Edit the package using RStudio:

- [`localhost:8004/rstudio`](localhost:8004/rstudio)
- User/PW: `opencpu`/`opencpu`
