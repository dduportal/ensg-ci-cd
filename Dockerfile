FROM node:13-alpine

LABEL Maintainers="Damien DUPORTAL<damien.duportal@gmail.com>"

# To handle 'not get uid/gid'
RUN npm config set unsafe-perm true

# Install Global dependencies and gulp 4.x globally
RUN apk add --no-cache \
      curl \
      git \
      tini \
  && npm install -g gulp npm-check-updates

# Install App's dependencies (dev and runtime)
COPY ./package.json /app/package.json
WORKDIR /app
RUN npm install

COPY ./gulp/tasks /app/tasks
COPY ./gulp/gulpfile.js /app/gulpfile.js

VOLUME ["/app"]

# HTTP
EXPOSE 8000

ENTRYPOINT ["/sbin/tini","-g","gulp"]
CMD ["default"]
