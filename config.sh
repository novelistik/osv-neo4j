#!/usr/bin/env bash

##
# Configure your neo4j instance.
#
#
# Either change the variables here or replace this script to copy
# your configuration files.
##

# Shamefully borrowed from neo4j docker base.
setting() {
    setting="${1}"
    value="${2}"
    file="${3}"

    if [ ! -f "conf/${file}" ]; then
        if [ -f "conf/neo4j.conf" ]; then
            file="neo4j.conf"
        fi
    fi

    if [ -n "${value}" ]; then
        sed --in-place "s|.*${setting}=.*|${setting}=${value}|" conf/"${file}"
    fi
}


setting "keep_logical_logs" "${NEO4J_KEEP_LOGICAL_LOGS:-100M size}" neo4j.properties
setting "dbms.pagecache.memory" "${NEO4J_CACHE_MEMORY:-512M}" neo4j.properties
setting "wrapper.java.additional=-Dneo4j.ext.udc.source" "${NEO4J_UDC_SOURCE:-docker}" neo4j-wrapper.conf
setting "wrapper.java.initmemory" "${NEO4J_HEAP_MEMORY:-512}" neo4j-wrapper.conf
setting "wrapper.java.maxmemory" "${NEO4J_HEAP_MEMORY:-512}" neo4j-wrapper.conf
setting "org.neo4j.server.thirdparty_jaxrs_classes" "${NEO4J_THIRDPARTY_JAXRS_CLASSES:-}" neo4j-server.properties
setting "allow_store_upgrade" "${NEO4J_ALLOW_STORE_UPGRADE:-}" neo4j.properties

if [ "${NEO4J_AUTH:-}" == "none" ]; then
    setting "dbms.security.auth_enabled" "false" neo4j-server.properties
elif [[ "${NEO4J_AUTH:-}" == neo4j/* ]]; then
    password="${NEO4J_AUTH#neo4j/}"
    bin/neo4j start || \
        (cat data/log/console.log && echo "Neo4j failed to start" && exit 1)

    end="$((SECONDS+10))"
    while true; do
        http_code="$(curl --silent --write-out %{http_code} --user "neo4j:${password}" --output /dev/null http://localhost:7474/db/data/ || true)"

        if [[ "${http_code}" = "200" ]]; then
            break;
        fi

        if [[ "${http_code}" = "403" ]]; then
            curl --fail --silent --show-error --user neo4j:neo4j \
                    --data '{"password": "'"${password}"'"}' \
                    --header 'Content-Type: application/json' \
                    http://localhost:7474/user/neo4j/password
            break;
        fi

        if [[ "${SECONDS}" -ge "${end}" ]]; then
            (cat data/log/console.log && echo "Neo4j failed to start" && exit 1)
        fi

        sleep 1
    done

    bin/neo4j stop
elif [ -n "${NEO4J_AUTH:-}" ]; then
    echo "Invalid value for NEO4J_AUTH: '${NEO4J_AUTH}'"
    exit 1
fi

setting "org.neo4j.server.webserver.address" "0.0.0.0" neo4j-server.properties
setting "org.neo4j.server.database.mode" "${NEO4J_DATABASE_MODE:-}" neo4j-server.properties
setting "ha.server_id" "${NEO4J_SERVER_ID:-}" neo4j.properties
setting "ha.server" "${NEO4J_HA_ADDRESS:-}:6001" neo4j.properties
setting "ha.cluster_server" "${NEO4J_HA_ADDRESS:-}:5001" neo4j.properties
setting "ha.initial_hosts" "${NEO4J_INITIAL_HOSTS:-}" neo4j.properties

[ -f "${EXTENSION_SCRIPT:-}" ] && . ${EXTENSION_SCRIPT}

if [ -d "${NEO4J_D:-}/conf" ]; then
    find ${NEO4J_D}/conf -type f -exec cp {} conf \;
fi

if [ -d "${NEO4J_D:-}/ssl" ]; then
    num_certs=$(ls ${NEO4J_D:-}/ssl/*.cert 2>/dev/null | wc -l)
    num_keys=$(ls ${NEO4J_D:-}/ssl/*.key 2>/dev/null | wc -l)
    if [ $num_certs == "1" -a $num_keys == "1" ]; then
        cert=$(ls ${NEO4J_D:-}/ssl/*.cert)
        key=$(ls ${NEO4J_D:-}/ssl/*.key)
        setting "dbms.security.tls_certificate_file" $cert neo4j-server.properties
        setting "dbms.security.tls_key_file" $key neo4j-server.properties
    else
        echo "You must provide exactly one *.cert and exactly one *.key in ${NEO4J_D:-}/ssl."
        exit 1
    fi
fi

if [ -d "${NEO4J_D:-}/plugins" ]; then
    find ${NEO4J_D:-}/plugins -type f -exec cp {} plugins \;
fi
