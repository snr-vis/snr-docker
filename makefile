all:
	docker login
	docker build --no-cache -t snr .
	docker tag snr paulklemm/snr:latest
	docker push paulklemm/snr:latest
