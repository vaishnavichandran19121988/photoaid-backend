FROM dart:3.7 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

# Run pub get with verbose output printed to stdout/stderr
RUN dart pub get --verbose

COPY . .

# Show Dart version and files in bin for debug info
RUN dart --version
RUN ls -l /app/bin

# Compile the server, print output to stdout/stderr
RUN dart compile exe bin/server.dart -o bin/server

# Final stage: minimal image with compiled binary
FROM scratch

COPY --from=build /app/bin/server /bin/server

EXPOSE 8080

CMD ["/bin/server"]
