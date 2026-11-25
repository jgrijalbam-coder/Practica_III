FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

COPY . .

RUN flutter pub get

EXPOSE 10000

CMD ["dart", "run", "bin/server.dart"]
