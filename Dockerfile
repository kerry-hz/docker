FROM postgres:10.3
ARG VERSION=7.4.1
LABEL maintainer="Citus Data https://citusdata.com" \
      org.label-schema.name="Citus" \
      org.label-schema.description="Scalable PostgreSQL for multi-tenant and real-time workloads" \
      org.label-schema.url="https://www.citusdata.com" \
      org.label-schema.vcs-url="https://github.com/citusdata/citus" \
      org.label-schema.vendor="Citus Data, Inc." \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

ENV CITUS_VERSION ${VERSION}.citus-1

# install Citus
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
    && curl -s https://install.citusdata.com/community/deb.sh | bash \
    && apt-get install -y postgresql-$PG_MAJOR-citus-7.4=$CITUS_VERSION \
                          postgresql-$PG_MAJOR-hll=2.10.2.citus-1 \
                          postgresql-$PG_MAJOR-topn=2.0.2 \
    && apt-get install -y postgresql-server-dev-10 postgresql-10-partman build-essential wget git\
    && cd /tmp/\
    && wget -q -O - http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2 | tar jxf -\
    && cd /tmp/scws-1.2.3/\
    && ./configure && make install\
    && cd /tmp/\
    && git clone https://github.com/amutu/zhparser.git\
    && cd zhparser/\
    && make &&  make install\
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*\
    && rm /tmp/* -rf

# add citus to default PostgreSQL config
RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/postgresql.conf.sample

# add scripts to run after initdb
COPY 000-configure-stats.sh 001-create-citus-extension.sql /docker-entrypoint-initdb.d/

# add health check script
COPY pg_healthcheck /

HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck
