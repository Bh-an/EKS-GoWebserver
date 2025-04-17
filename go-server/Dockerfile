FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
# Flags remove Debug binaries, making the image smol
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s -extldflags '-static'" -o go-server ./cmd/go-server/main.go

# Using distroless instead of scratch because because it allows user management which scratch does not
FROM gcr.io/distroless/static AS final

USER 1001:1001

WORKDIR /app

# static binaries
COPY --from=builder --chown=1001:1001 /app/go-server /app/go-server
COPY --from=builder --chown=1001:1001 /app/config.json /app/config.json

EXPOSE 8080
ENTRYPOINT ["/app/go-server"]