FROM redis:alpine
WORKDIR /app
RUN apk add --no-cache \
	gcc \
	musl-dev \
	linux-headers \
	git \
	vim
EXPOSE 6379
COPY . .
CMD ["redis-server", "./redis.conf"]
