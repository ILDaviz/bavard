FROM dart:stable

RUN apt-get update && apt-get install -y postgresql-client

WORKDIR /app

COPY . /app/bavard/

WORKDIR /app/bavard/example/postgresql-docker

RUN dart pub get

CMD ["dart", "run", "main.dart"]
