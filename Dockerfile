FROM golang:1.20.4-alpine3.17 as builder

RUN apk --no-cache add git openssh-client \
                && adduser -D -u 1000 non-privileged \
                && mkdir /fluent \
                && chown -R 1000:1000 /fluent
#RUN git clone https://github.com/fluent/fluent-operator.git
RUN echo $(ls -al /fluent-operator/cmd)
WORKDIR /fluent-operator
# Copy the Go Modules manifests
ADD /fluent-operator /fluent-operator
RUN echo $(ls -al /fluent-operator/cmd)
COPY go.mod go.mod
COPY go.sum go.sum
#ENV GOPATH=/fluent-operator
RUN echo $GOPATH
RUN test -d /fluent-operator/cmd

RUN echo $PATH
#COPY go.mod go.mod
#COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN cd /fluent-operator
RUN go mod download



RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o manager /fluent-operator/cmd/fluent-manager/main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM kubesphere/distroless-static:nonroot
WORKDIR /
COPY --from=builder /fluent-operator/manager .
USER nonroot:nonroot

ENTRYPOINT ["/manager"]
