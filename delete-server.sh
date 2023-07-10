if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi

for master in master-0 master-1 master-2; do
	openstack server delete --wait $master 
	openstack volume delete $master-iso
	openstack volume delete $master-volume
done

for worker in `openstack server list | grep "worker-" | awk '{print $4;}'`; do
	openstack server delete --wait $worker
    openstack volume delete $worker-iso
	openstack volume delete $worker-volume
done



