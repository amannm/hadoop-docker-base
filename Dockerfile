FROM amannm/java8-docker-base
MAINTAINER Amann Malik <amannmalik@gmail.com>

WORKDIR /root

# Install dependencies from packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    git curl ant make maven \
    cmake gcc g++ protobuf-compiler \
    build-essential libtool \
    zlib1g-dev pkg-config libssl-dev \
    snappy libsnappy-dev \
    bzip2 libbz2-dev \
    libjansson-dev \
    fuse libfuse-dev \
    libcurl4-openssl-dev \
    python python2.7

# Install Forrest
RUN mkdir -p /usr/local/apache-forrest ; \
    curl -O http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz ; \
    tar xzf *forrest* --strip-components 1 -C /usr/local/apache-forrest ; \
    echo 'forrest.home=/usr/local/apache-forrest' > build.properties

# Install findbugs
RUN mkdir -p /opt/findbugs && \
    wget http://sourceforge.net/projects/findbugs/files/findbugs/3.0.1/findbugs-noUpdateChecks-3.0.1.tar.gz/download \
         -O /opt/findbugs.tar.gz && \
    tar xzf /opt/findbugs.tar.gz --strip-components 1 -C /opt/findbugs
ENV FINDBUGS_HOME /opt/findbugs

# Install shellcheck
RUN apt-get install -y cabal-install
RUN cabal update && cabal install shellcheck --global

#####
# bats
#####

RUN add-apt-repository ppa:duggan/bats --yes
RUN apt-get update -qq
RUN apt-get install -qq bats

# Fixing the Apache commons / Maven dependency problem under Ubuntu:
# See http://wiki.apache.org/commons/VfsProblems
RUN cd /usr/share/maven/lib && ln -s ../../java/commons-lang.jar .

# Avoid out of memory errors in builds
ENV MAVEN_OPTS -Xms256m -Xmx512m

# Add a welcome message and environment checks.
ADD hadoop_env_checks.sh /root/hadoop_env_checks.sh
RUN chmod 755 /root/hadoop_env_checks.sh
RUN echo '~/hadoop_env_checks.sh' >> /root/.bashrc


RUN mvn package -Pdist,native -DskipTests

ENV HADOOP_VERSION 2.7.1
ENV HADOOP_PREFIX /opt/hadoop
ENV HADOOP_CONF_DIR $HADOOP_PREFIX/conf
ENV PATH $PATH:$HADOOP_PREFIX/bin
ENV PATH $PATH:$HADOOP_PREFIX/sbin


RUN wget http://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf /hadoop-$HADOOP_VERSION.tar.gz && \
    rm /hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_PREFIX && \
    mkdir -p $HADOOP_VERSION/logs

VOLUME /shared

ADD core-site.xml $HADOOP_CONF_DIR/core-site.xml
ADD hdfs-site.xml $HADOOP_CONF_DIR/hdfs-site.xml