set -x

if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi
if [[ "$cidr" == "" ]]; then echo "cidr base not set"; exit 3; fi

#public ip API
openstack floating ip create Ext-Net --description "$name-api"
#public ip Ingress
openstack floating ip create Ext-Net --description "$name-ingress"

#create private network
openstack network create openshift-$name
openstack subnet create openshift-$name-subnet --subnet-range $cidr.0/24 --network openshift-$name --dns-nameserver 213.186.33.99
openstack router create openshift-$name-router
openstack router add subnet openshift-$name-router openshift-$name-subnet 
openstack router set --external-gateway Ext-Net openshift-$name-router

#private ip API
openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$cidr.7 $name-api
#private ip Ingress
openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$cidr.8 $name-ingress
#private ips for masters and workers
openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$cidr.9 $name-bootstrap
openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$cidr.10 $name-master-0
openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$cidr.11 $name-master-1
openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$cidr.12 $name-master-2

subnet=`openstack network show openshift-$name -f json | jq -r .subnets[0]`

#create LB for API
openstack loadbalancer create --name openshift-$name-api --flavor small --vip-port-id $name-api --wait

openstack loadbalancer listener create --name openshift-$name-api-listener --protocol TCP --protocol-port 6443 openshift-$name-api --wait

openstack loadbalancer pool create --name openshift-$name-api-pool --lb-algorithm ROUND_ROBIN --listener openshift-$name-api-listener --protocol TCP --wait

#add master ips to API LB
openstack loadbalancer member create --subnet-id $subnet --address $cidr.9 --protocol-port 6443 openshift-$name-api-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.10 --protocol-port 6443 openshift-$name-api-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.11 --protocol-port 6443 openshift-$name-api-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.12 --protocol-port 6443 openshift-$name-api-pool --wait

openstack loadbalancer listener create --name openshift-$name-api-ignition-listener --protocol TCP --protocol-port 22623 openshift-$name-api --wait

openstack loadbalancer pool create --name openshift-$name-api-ignition-pool --lb-algorithm ROUND_ROBIN --listener openshift-$name-api-ignition-listener --protocol TCP --wait

openstack loadbalancer member create --subnet-id $subnet --address $cidr.9 --protocol-port 22623 openshift-$name-api-ignition-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.10 --protocol-port 22623 openshift-$name-api-ignition-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.11 --protocol-port 22623 openshift-$name-api-ignition-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.12 --protocol-port 22623 openshift-$name-api-ignition-pool --wait

#set public API ip to API LB private ip
ip_api=`openstack floating ip list -f json --long | jq -r '.[] | select(.Description == "'$name'-api") | ."Floating IP Address"'`
port_api=`openstack loadbalancer show openshift-$name-api -f json | jq -r .vip_port_id`
openstack floating ip set --port $port_api $ip_api

#create LB for Ingress
openstack loadbalancer create --name openshift-$name-ingress --flavor small --vip-port-id $name-ingress --wait

openstack loadbalancer listener create --name openshift-$name-ingress-listener --protocol TCP --protocol-port 443 openshift-$name-ingress --wait
openstack loadbalancer listener create --name openshift-$name-ingress-80-listener --protocol TCP --protocol-port 80 openshift-$name-ingress --wait

openstack loadbalancer pool create --name openshift-$name-ingress-pool --lb-algorithm ROUND_ROBIN --listener openshift-$name-ingress-listener --protocol TCP --wait
openstack loadbalancer pool create --name openshift-$name-ingress-80-pool --lb-algorithm ROUND_ROBIN --listener openshift-$name-ingress-80-listener --protocol TCP --wait

#add worker ips to Ingress LB
openstack loadbalancer member create --subnet-id $subnet --address $cidr.10 --protocol-port 443 openshift-$name-ingress-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.11 --protocol-port 443 openshift-$name-ingress-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.12 --protocol-port 443 openshift-$name-ingress-pool --wait

openstack loadbalancer member create --subnet-id $subnet --address $cidr.10 --protocol-port 80 openshift-$name-ingress-80-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.11 --protocol-port 80 openshift-$name-ingress-80-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $cidr.12 --protocol-port 80 openshift-$name-ingress-80-pool --wait

#set public Ingress ip to Ingress LB private ip
ip_ingress=`openstack floating ip list -f json --long | jq -r '.[] | select(.Description == "'$name'-ingress") | ."Floating IP Address"'`
port_ingress=`openstack loadbalancer show openshift-$name-ingress -f json | jq -r .vip_port_id`
openstack floating ip set --port $port_ingress $ip_ingress

