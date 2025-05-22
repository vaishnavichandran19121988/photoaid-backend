FROM dart:stable AS build

WORKDIR /app

RUN dart pub cache clean

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .

RUN ls -l bin
RUN dart --version
RUN dart pub deps
RUN find . -type f
RUN cat bin/server.dart | head -20
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch

WORKDIR /app

COPY --from=build /app/bin/server /bin/server

EXPOSE 8080

CMD ["/bin/server"]
