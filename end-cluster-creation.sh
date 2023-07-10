
if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi
if [[ "$cidr" == "" ]]; then echo "cidr base not set"; exit 2; fi

id=`openstack loadbalancer member list openshift-$name-api-ignition-pool -f json | jq -r '.[] | select(.address == "'$cidr'.9") | .id'`
openstack loadbalancer member delete --wait openshift-$name-api-ignition-pool $id

id=`openstack loadbalancer member list openshift-$name-api-pool -f json | jq -r '.[] | select(.address == "'$cidr'.9") | .id'`
openstack loadbalancer member delete --wait openshift-$name-api-pool $id 

openstack server delete --wait $name-bootstrap
openstack volume delete $name-bootstrap-iso
openstack volume delete $name-bootstrap-volume

openstack port delete $name-bootstrap


