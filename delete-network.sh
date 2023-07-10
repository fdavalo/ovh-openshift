set -x

if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi

ip_ingress=`openstack floating ip list -f json --long | jq -r '.[] | select(.Description == "'$name'-ingress") | ."Floating IP Address"'`
openstack floating ip delete $ip_ingress

ip_api=`openstack floating ip list -f json --long | jq -r '.[] | select(.Description == "'$name'-api") | ."Floating IP Address"'`
openstack floating ip delete $ip_api

openstack loadbalancer pool delete --wait openshift-$name-api-pool
openstack loadbalancer pool delete --wait openshift-$name-api-ignition-pool
openstack loadbalancer pool delete --wait openshift-$name-ingress-pool
openstack loadbalancer pool delete --wait openshift-$name-ingress-80-pool

openstack loadbalancer listener delete --wait openshift-$name-api-listener 
openstack loadbalancer listener delete --wait openshift-$name-api-ignition-listener
openstack loadbalancer listener delete --wait openshift-$name-ingress-listener 
openstack loadbalancer listener delete --wait openshift-$name-ingress-80-listener

openstack loadbalancer delete --wait openshift-$name-ingress
openstack loadbalancer delete --wait openshift-$name-api

openstack port delete $name-api
openstack port delete $name-ingress
openstack port delete $name-bootstrap
openstack port delete $name-master-0
openstack port delete $name-master-1
openstack port delete $name-master-2
openstack port list | grep "$name-worker-" | awk '{system("openstack port delete "$2);}'


openstack router remove subnet openshift-$name-router openshift-$name-subnet 

openstack router delete openshift-$name-router
openstack subnet delete openshift-$name-subnet
openstack network delete openshift-$name


