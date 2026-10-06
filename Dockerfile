FROM eclipse-temurin:11-jdk-jammy
ARG HBASE_VERSION=2.5.16
ARG HBASE_SHA512
ENV HBASE_HOME=/opt/hbase PATH=/opt/hbase/bin:/opt/hbase/conf:$PATH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates procps python3 && rm -rf /var/lib/apt/lists/* \
 && curl -fL --retry 3 "https://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz" -o /tmp/hbase.tgz \
 && if [ -n "$HBASE_SHA512" ]; then echo "$HBASE_SHA512  /tmp/hbase.tgz" | sha512sum -c -; fi \
 && tar -xzf /tmp/hbase.tgz -C /opt && ln -s "/opt/hbase-${HBASE_VERSION}" /opt/hbase && rm /tmp/hbase.tgz
COPY conf/hbase-site.xml /opt/hbase/conf/hbase-site.xml
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /var/lib/hbase /workspace
WORKDIR /workspace
EXPOSE 16000 16010 16020 16030 2181
ENTRYPOINT ["/entrypoint.sh"]
