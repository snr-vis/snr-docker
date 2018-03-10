# 🐳 Sonar OpenCPU Dockerfile

<!-- TOC -->

- [🐳 Sonar OpenCPU Dockerfile](#🐳-sonar-opencpu-dockerfile)
  - [Credit](#credit)
  - [TODO](#todo)
  - [Build Container and Push to DockerHub](#build-container-and-push-to-dockerhub)
  - [Run Container](#run-container)
  - [Run Container Dev Mode](#run-container-dev-mode)
  - [Links](#links)
  - [Git Setup](#git-setup)

<!-- /TOC -->

## Credit

This Dockerfile uses code from [https://github.com/opencpu/opencpu-server/tree/master/docker](https://github.com/opencpu/opencpu-server/tree/master/docker):

* [https://github.com/opencpu/opencpu-server/blob/master/docker/base/Dockerfile](https://github.com/opencpu/opencpu-server/blob/master/docker/base/Dockerfile)
* [https://github.com/opencpu/opencpu-server/blob/master/docker/rstudio/Dockerfile](https://github.com/opencpu/opencpu-server/blob/master/docker/rstudio/Dockerfile)

Simply because we need to start the OpenCPU server as last step to load overwritten packages. The `sudo apachectl restart` command seems to crash the docker container, therefore this hacky solution is required.

## TODO

Issues related to [SNR-GO](https://github.sf.mpg.de/pklemm/sonargo):

* [ ] Call `get_go_summary` for all important species of the current ensembl release on package compile
* [x] Increase opencpu response time to allow for `get_go_summary` to properly execute
* [ ] Fix common folder `/usr/local/var/ensembl` or make it the primary one - [https://github.sf.mpg.de/pklemm/sonargo/issues/2](https://github.sf.mpg.de/pklemm/sonargo/issues/2)
* [x] Fix `rlang` version hack by specifying proper dependencies in the snrgo and snr `R` package - [https://github.sf.mpg.de/pklemm/sonargo/issues/3](https://github.sf.mpg.de/pklemm/sonargo/issues/3)

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

* `data` contains the differential gene expression data

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

_Release Paths:_

```bash
docker pull paulklemm/snr
docker run -t -d \
    #-p 8004:8004 \
    -p 8080:8080 \
    -v sonar:/home/opencpu/sonar \
    --name opencpu_rstudio_test \
    paulklemm/snr
```

_Macbook Paths:_

```bash
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/data:/home/opencpu/sonar/data \
    -v /Users/paul/Workshop/MPI/MPI-MR-Projects/SONAR/app/sona-R:/home/opencpu/sonar/sonaR \
    --name opencpu_rstudio \
    paulklemm/snr
```

_Aligner Paths:_

```bash
docker pull paulklemm/snr
docker run -t -d -p 80:80 \
    -p 8004:8004 \
    -v /opt/sonar/data:/home/opencpu/sonar/data \
    -v /opt/sonar/sona-R:/home/opencpu/sonar/sonaR \
    --name opencpu_rstudio \
    paulklemm/snr
```

Edit the package using RStudio:

* [`localhost:8004/rstudio`](localhost:8004/rstudio)
* User/PW: `opencpu`/`opencpu`

## Links

* [How to include and preload data in OpenCPU packages](https://www.opencpu.org/posts/scoring-engine/) ([.onLoad call](https://github.com/rwebapps/tvscore/blob/master/R/onLoad.R))

## Git Setup

Dev comment: this repo knows two origins:

```bash
# From https://stackoverflow.com/questions/14290113/git-pushing-code-to-two-remotes
git remote set-url --add --push origin git@github.com:snr-vis/snr-docker.git
git remote set-url --add --push origin git@github.sf.mpg.de:pklemm/snr-docker.git
# Check with `git remote show origin`
```