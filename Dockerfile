FROM dart:3.7 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

# Capture pub get output to build_pub_get.log
RUN dart pub get --verbose > build_pub_get.log 2>&1

COPY . .

# Capture Dart version and bin folder listing
RUN dart --version > build_dart_version.log 2>&1
RUN ls -l /app/bin > build_bin_listing.log 2>&1

# Compile server, log output
RUN dart compile exe bin/server.dart -o bin/server > build_compile.log 2>&1

# Expose logs as artifacts (optional)
RUN mkdir /app/build_logs && \
    cp build_pub_get.log build_dart_version.log build_bin_listing.log build_compile.log /app/build_logs/

FROM scratch

COPY --from=build /app/bin/server /bin/server
COPY --from=build /app/build_logs /build_logs

EXPOSE 8080

# Run the server, and ensure stdout/stderr go to Docker logs
CMD ["/bin/server"]
