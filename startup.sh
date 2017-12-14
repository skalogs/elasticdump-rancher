#!/usr/bin/env bash
set -e

RANCHER_BASEURL="rancher-metadata.rancher.internal/latest"

if [ -z "${SERVICE_ELASTICSEARCH_USERNAME}" ]; then
  ES_AUTH=""
else
  ES_AUTH="${SERVICE_ELASTICSEARCH_USERNAME}:${SERVICE_ELASTICSEARCH_PASSWORD}@"
fi
ES_URL=http://${ES_AUTH}${SERVICE_ELASTICSEARCH_HOST}:${SERVICE_ELASTICSEARCH_PORT}

function checkElasticsearch {
    a="`curl ${ES_URL}/_cluster/health &> /dev/null; echo $?`"
    while  [ $a -ne 0 ];
    do
        a="`curl ${ES_URL}/_cluster/health &> /dev/null; echo $?`"
        sleep 1
    done
}

checkElasticsearch

echo "Restoring elasticsearch dump"
curl ${RANCHER_BASEURL}/self/service/metadata/elasticdump > /tmp/elasticdump.json
/usr/lib/node_modules/elasticdump/bin/elasticdump --input=/tmp/elasticdump.json --output=${ES_URL}/${TARGET_INDEX} --headers='{"Content-Type": "application/json"}' ${ELASTICDUMP_OPTS}

if [ ! -z "${DEFAULT_INDEX_PATTERN}" ]; then
    curl http://${ES_AUTH}${SERVICE_KIBANA_HOST}:${SERVICE_KIBANA_PORT}/api/kibana/settings/defaultIndex \
	    -H "Content-Type: application/json" \
	    -H "kbn-xsrf: anything" \
	    --data-binary '{"value":"'${DEFAULT_INDEX_PATTERN}'"}' \
	    --compressed
fi
