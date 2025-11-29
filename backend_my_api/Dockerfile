# Stage 1: Build the code
FROM dart:stable AS build

WORKDIR /app

# Copy dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source and build
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Run the code
# FIX: Use 'dart:stable' instead of 'debian:slim'
# This ensures all SSL/TLS libraries and Certificates are perfect.
FROM dart:stable

# Copy the compiled server
COPY --from=build /app/bin/server /app/bin/server

# Expose the port
EXPOSE 8080

# Start the server
CMD ["/app/bin/server"]