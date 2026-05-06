FROM python:3.14-alpine AS builder
WORKDIR /tmp
# Install Git executable and copy Git folder to determine last commit date for documentation build on index page
RUN apk upgrade --update-cache -a \
 && apk add --no-cache git\
 && rm -rf /var/cache/apk/*
COPY .git .git
# Copy Python requirements file and installing dependencies
COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt
# Copy documentation source files to working directory
COPY docs docs
COPY includes includes
COPY zensical.toml .
# Build new documentation
RUN zensical build --strict

FROM python:3.14-alpine
STOPSIGNAL SIGKILL
RUN adduser -D docs
USER docs
WORKDIR /tmp
# Only copying the generated documentation from the builder stage to reduce image size and leave out unused files and dependencies
COPY --from=builder /tmp/site ./site
EXPOSE 8080
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:8080 || exit 1
# Run webserver
CMD ["python", "-m", "http.server", "8080", "-d", "site/"]
