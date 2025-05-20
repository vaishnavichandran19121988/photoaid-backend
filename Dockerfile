# Use Dart's official image
FROM dart:stable

# Set working directory
WORKDIR /app

# Copy pubspec and get dependencies first (cache-friendly)
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the code
COPY . .

# Compile the server (optional but good practice)
RUN dart compile exe bin/server.dart -o bin/server

# Run the compiled server
CMD ["./bin/server"]
