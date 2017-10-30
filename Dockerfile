FROM alpine:3.6

RUN apk --update add bash nodejs nodejs-npm
ENV ELASTICDUMP_VERSION 3.3.1
RUN npm install -g elasticdump@${ELASTICDUMP_VERSION}

CMD ["/usr/bin/elasticdump"]
