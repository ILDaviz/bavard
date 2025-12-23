FROM dart:stable

# Install sqlite3 library
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev

WORKDIR /app

# Copy the bavard source code
# Context is expected to be the project root
COPY . /app/bavard/

# Create a clean directory for the test app
WORKDIR /app/test

# Copy test files from the context
COPY /examples/sqlite-docker/pubspec.yaml .
COPY /examples/sqlite-docker/main.dart .

# Resolve dependencies
# The pubspec.yaml points to /app/bavard
RUN dart pub get

# Run the test
CMD ["dart", "run", "main.dart"]
