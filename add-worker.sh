set -x

if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi
if [[ "$cidr" == "" ]]; then echo "cidr base not set"; exit 2; fi

flavor=$1
if [[ "$flavor" == "" ]]; then flavor=b2-15; fi

dir=iso/$name

#look for available slot for new worker
ind=0
while [[ $ind -lt 80 ]]; do
  openstack port show $name-worker-$ind
  if [[ $? -ne 0 ]]; then break; fi
  let ind=ind+1
done

if [[ $ind -eq 80 ]]; then echo "max worker reached"; exit 1; fi

let ipn=ind+20
ip=$cidr.$ipn
worker=worker-$ind

openstack port create --network openshift-$name --fixed-ip subnet=openshift-$name-subnet,ip-address=$ip $name-$worker

subnet=`openstack network show openshift-$name -f json | jq -r .subnets[0]`
openstack loadbalancer member create --subnet-id $subnet --address $ip --protocol-port 443 openshift-$name-ingress-pool --wait
openstack loadbalancer member create --subnet-id $subnet --address $ip --protocol-port 80 openshift-$name-ingress-80-pool --wait

iso_id=`openstack image list -f json | jq -r '.[] | select(.Name == "'$name'-worker.iso") | .ID'`

openstack volume create --size=2 --image=$iso_id  --bootable $name-$worker-iso
iso_vol_id=`openstack volume list -f json | jq -r '.[] | select(.Name == "'$name'-'$worker'-iso") | .ID'`

openstack volume create --size=120  --bootable $name-$worker-volume
vol_id=`openstack volume list -f json | jq -r '.[] | select(.Name == "'$name'-'$worker'-volume") | .ID'`

openstack server create --flavor $flavor --port $name-$worker --block-device uuid=$iso_vol_id,source_type=volume,destination_type=volume,disk_bus=ide,device_name=/dev/vda,volume_size=2,device_type=cdrom,boot_index=1 --block-device source_type=volume,uuid=$vol_id,destination_type=volume,device_name=/dev/hda,volume_size=120,boot_index=0 --security-group default --wait $name-$worker 

sleep 300

export KUBECONFIG=$dir/auth/kubeconfig

nodename=`echo host-$ip | sed -e "s/\./-/g"`
no=0
while [[ $no -lt 60 ]]; do 
	nb=`oc get node $nodename | grep $nodename | wc -l`
	if [[ $nb -eq 1 ]]; then break; fi
	for i in `oc get csr --no-headers | grep -i pending |  awk '{ print $1 }'`; do oc adm certificate approve $i; done
	sleep 60
	for i in `oc get csr --no-headers | grep -i pending |  awk '{ print $1 }'`; do oc adm certificate approve $i; done
	sleep 60
	let no=no+1
done

if [[ $no -eq 60 ]]; then echo "timeout with no worker available"; exit 2; fi


