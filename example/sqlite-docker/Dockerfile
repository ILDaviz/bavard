FROM dart:stable

# Install sqlite3 library
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev

WORKDIR /app

# Copy the bavard source code
# Context is expected to be the project root
COPY . /app/bavard/

# Work inside the example directory within the copied repo
WORKDIR /app/bavard/example/sqlite-docker

# Resolve dependencies
# The pubspec.yaml here uses relative paths which are now valid
RUN dart pub get

# Run the test
CMD ["dart", "run", "main.dart"]
