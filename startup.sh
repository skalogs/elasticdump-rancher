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
        echo "I'm waiting Elasticsearch"
	sleep 5
    done
}

function checkKibana {
    curlCommand="curl --silent ${KIBANA_URL}/api/status -H 'Content-Type: application/json;charset=UTF-8' --write-out %{http_code} --output /dev/null"
    status=$(eval $curlCommand)
    while  [ $status -ne 200 ] ;
    do
        status=$(eval $curlCommand)
	echo "I'm waiting Kibana"
        sleep 5
    done
}

checkElasticsearch
checkKibana

INDEX_PATTERN=$(curl --silent ${RANCHER_BASEURL}/self/service/metadata/elasticdump)

if [ ! -z "${INDEX_PATTERN}" ]; then
    while read INDEX TIME_FIELD ; do
        echo "Create index pattern"
        curl -f -XPOST "$KIBANA_URL/api/saved_objects/index-pattern/$INDEX" \
             -H "Content-Type: application/json" \
             -H "kbn-xsrf: anything" \
             --data-binary "{\"attributes\":{\"title\":\"$INDEX\",\"timeFieldName\":\"$TIME_FIELD\"}}" \
             --compressed
    done <<< "$INDEX_PATTERN"

    if [ ! -z "${DEFAULT_INDEX_PATTERN}" ]; then
        echo "Setting default index pattern"
        curl ${KIBANA_URL}/api/kibana/settings/defaultIndex \
	         -H "Content-Type: application/json" \
	         -H "kbn-xsrf: anything" \
	         --data-binary '{"value":"'${DEFAULT_INDEX_PATTERN}'"}' \
	         --compressed
    fi
fi
