FROM golang:1.22

# create and set default directory for service  files
RUN mkdir /app
WORKDIR /app

COPY . .
RUN go mod tidy
RUN go install .
RUN mv $GOPATH/bin/caller $GOPATH/bin/caller_server

CMD ["caller_server"]
