#name=rhods2
#basedomain=geotec.xyz

if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi
if [[ "$cidr" == "" ]]; then echo "cidr base not set"; exit 2; fi

ip_api=`openstack floating ip list -f json --long | jq -r '.[] | select(.Description == "'$name'-api") | ."Floating IP Address"'`
ip_ingress=`openstack floating ip list -f json --long | jq -r '.[] | select(.Description == "'$name'-ingress") | ."Floating IP Address"'`

python3 create-dns.py $basedomain "*.apps.$name" $ip_ingress
python3 create-dns.py $basedomain "api.$name" $ip_api
python3 create-dns.py $basedomain "api-int.$name" $cidr.7 

