all:
	docker login
	docker build --no-cache -t snr .
	docker tag snr paulklemm/snr:paperrelease
	docker push paulklemm/snr:paperrelease
