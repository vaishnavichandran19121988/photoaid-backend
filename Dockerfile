FROM dart:stable AS build

WORKDIR /app

RUN dart pub cache clear


COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .

RUN dart compile exe bin/server.dart -o bin/server

FROM scratch

WORKDIR /app

COPY --from=build /app/bin/server /bin/server

EXPOSE 8080

CMD ["/bin/server"]
