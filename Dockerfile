FROM python:3.7-alpine
WORKDIR /app
ENV flask_app=app.py
ENV FLASK_RUN_HOST=0.0.0.0
RUN apk add --no-cache \
	gcc \
	musl-dev \
	linux-headers \
    curl \
	git \
	vim
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
EXPOSE 5000
COPY . .
CMD ["echo", "---running---"]
CMD ["flask", "run"]
