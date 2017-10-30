FROM taskrabbit/elasticsearch-dump:v3.3.1

ADD startup.sh /usr/bin/startup.sh

ENTRYPOINT ["/usr/bin/startup.sh"]
