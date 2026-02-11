FROM dart:stable

# Install sqlite3 library
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev

WORKDIR /app

COPY . /app/bavard/

WORKDIR /app/bavard/example/sqlite-docker

RUN dart pub get

CMD ["dart", "run", "main.dart"]
