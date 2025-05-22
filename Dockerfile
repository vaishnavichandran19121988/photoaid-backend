# Use specific Dart SDK version for consistency (optional)
FROM dart:3.7 AS build

# Set working directory inside container
WORKDIR /app

# Copy only pubspec files and get dependencies first (to leverage Docker cache)
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --verbose

# Copy all source files
COPY . .

# Show Dart version and source files to debug
RUN dart --version
RUN ls -l /app/bin

# Compile the server executable
RUN dart compile exe bin/server.dart -o bin/server

# Final image: use smaller base for running only the compiled binary
FROM scratch

# Copy the compiled server binary from build stage
COPY --from=build /app/bin/server /bin/server

# Expose any ports if necessary (e.g., 8080)
EXPOSE 8080

# Run the server binary
CMD ["/bin/server"]
