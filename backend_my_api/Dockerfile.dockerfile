# 1. Use the official Dart image to build the app
FROM dart:stable AS build

# Set the working directory
WORKDIR /app

# Copy the recipe files (pubspec)
COPY pubspec.* ./
# Get the ingredients (dependencies)
RUN dart pub get

# Copy the rest of the code
COPY . .

# Ensure dependencies are online
RUN dart pub get --offline
# Cook (Compile) the code into a binary file called "server"
RUN dart compile exe bin/server.dart -o bin/server

# 2. Create the tiny shipping container for production
FROM debian:stable-slim

# Copy the compiled server from the build stage
COPY --from=build /app/bin/server /app/bin/server

# Install certificates so MongoDB SSL works
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Open port 8080
EXPOSE 8080

# Start the server
CMD ["/app/bin/server"]