FROM dart:stable

RUN apt-get update && apt-get install -y postgresql-client

WORKDIR /app

COPY . /app/bavard/

WORKDIR /app/test

COPY /example/postgresql-docker/pubspec.yaml .
COPY /example/postgresql-docker/main.dart .

RUN dart pub get

CMD ["dart", "run", "main.dart"]
