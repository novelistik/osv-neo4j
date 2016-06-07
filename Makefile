.PHONY: module

NEO4J_VERSION := 3.0.0-M05
NEO4J_EDITION := enterprise
NEO4J_DOWNLOAD_ROOT := http://dist.neo4j.org
NEO4J_TARBALL := neo4j-$(NEO4J_EDITION)-$(NEO4J_VERSION)-unix.tar.gz
NEO4J_URI := $(NEO4J_DOWNLOAD_ROOT)/$(NEO4J_TARBALL)

neo4j.tar.gz:
	curl --fail --show-error --location --output neo4j.tar.gz $(NEO4J_URI) \
    && echo "$(NEO4J_DOWNLOAD_SHA256) neo4j.tar.gz"

ROOTFS/neo4j: neo4j.tar.gz
	mkdir -p ROOTFS && \
	tar --extract --file neo4j.tar.gz --directory ROOTFS/ && \
  mv ROOTFS/neo4j-$(NEO4J_EDITION)-$(NEO4J_VERSION) ROOTFS/neo4j


module:
	echo hello
