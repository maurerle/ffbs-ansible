#!/bin/bash
source /etc/profile.d/etcd.sh
PUT="etcdctl put"
GET="etcdctl get"

etcdctl endpoint health
if [[ $? -gt 0 ]]; then
    echo "cluster unhealthy, skipping"
    exit 0
fi

# do not overwrite these values
initialized=$($GET initialized)
if [[ -n "$initialized" ]]; then
    echo "already initialized, aborting"
    exit 0
fi

# insert default values
$PUT '/config/default/retry' 20
$PUT '/config/default/wg_keepalive' 25
$PUT '/config/default/mtu' 1420
$PUT '/config/default/concentrators' '[{% for host in groups['etcd_cluster'] %}{"address4": "{{hostvars[host]['wg_gateway_v4']}}", "address6": "{{hostvars[host]['wg_gateway_v6']}}", "endpoint": "{{host}}:10000", "pubkey": "{{hostvars[host]['wg_public_key']}}", "id": {{hostvars[host]['wg_backbone_id']}}}{% if not loop.last %}, {% endif %}{% endfor %}]'

$PUT 'next_free_id' 1
$PUT 'initialized' "$(date)"

