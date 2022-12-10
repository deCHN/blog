broker-quic: clean
	docker run -d --name emqx \
		-p 1883:1883 -p 8083:8083 \
		-p 8084:8084 -p 8883:8883 \
		-p 18083:18083 \
		-p 14567:14567/udp \
		-e EMQX_LISTENERS__QUIC__DEFAULT__keyfile="~/gocode/h2web/key.pem" \
		-e EMQX_LISTENERS__QUIC__DEFAULT__certfile="~/gocode/h2web/cert.pem" \
		-e EMQX_LISTENERS__QUIC__DEFAULT__ENABLED=true \
		emqx/emqx:5.0.11

broker: clean
	docker run -d --name emqx \
		-p 1883:1883 -p 8083:8083 \
		-p 8084:8084 -p 8883:8883 \
		-p 18083:18083 \
		emqx/emqx:5.0.11

client: clean
	docker run -d --name nanomq emqx/nanomq:0.14.1

clean:
	docker rm -f nanomq
	docker rm -f emqx


