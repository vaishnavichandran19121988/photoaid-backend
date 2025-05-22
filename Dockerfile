FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files first for caching
COPY pubspec.yaml pubspec.lock ./



# Then get dependencies based on upgraded versions
RUN dart pub get --verbose

# Copy rest of source files
COPY . .

# Compile your server executable (if needed)
RUN dart compile exe bin/server.dart -o bin/server

# Final image for runtime
FROM scratch

COPY --from=build /app/bin/server /bin/server

EXPOSE 8080

CMD ["/bin/server"]
