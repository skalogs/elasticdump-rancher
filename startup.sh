#!/usr/bin/env bash
set -e

RANCHER_BASEURL="rancher-metadata.rancher.internal/latest"

if [ -z "${SERVICE_ELASTICSEARCH_USERNAME}" ]; then
  ES_AUTH=""
else
  ES_AUTH="${SERVICE_ELASTICSEARCH_USERNAME}:${SERVICE_ELASTICSEARCH_PASSWORD}@"
fi
ES_URL=http://${ES_AUTH}${SERVICE_ELASTICSEARCH_HOST}:${SERVICE_ELASTICSEARCH_PORT}
KIBANA_URL=http://${ES_AUTH}${SERVICE_KIBANA_HOST}:${SERVICE_KIBANA_PORT}

function checkElasticsearch {
    curlCommand="curl --silent ${ES_URL}/_cluster/health -H 'Content-Type: application/json;charset=UTF-8' --write-out %{http_code} --output /dev/null"
    status=$(eval $curlCommand)
    while  [ $status -ne 200 ] ;
    do
        status=$(eval $curlCommand)
        sleep 1
    done
}

function checkKibana {
    curlCommand="curl --silent ${KIBANA_URL}/api/status -H 'Content-Type: application/json;charset=UTF-8' --write-out %{http_code} --output /dev/null"
    status=$(eval $curlCommand)
    while  [ $status -ne 200 ] ;
    do
        status=$(eval $curlCommand)
        sleep 1
    done
}

checkElasticsearch
checkKibana

echo "Restoring elasticsearch dump"
curl ${RANCHER_BASEURL}/self/service/metadata/elasticdump > /tmp/elasticdump.json
/usr/lib/node_modules/elasticdump/bin/elasticdump --input=/tmp/elasticdump.json --output=${ES_URL}/${TARGET_INDEX} --headers='{"Content-Type": "application/json"}' ${ELASTICDUMP_OPTS}

if [ ! -z "${DEFAULT_INDEX_PATTERN}" ]; then
    curl ${KIBANA_URL}/api/kibana/settings/defaultIndex \
	    -H "Content-Type: application/json" \
	    -H "kbn-xsrf: anything" \
	    --data-binary '{"value":"'${DEFAULT_INDEX_PATTERN}'"}' \
	    --compressed
fi
