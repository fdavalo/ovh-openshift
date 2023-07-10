set -x

#name=rhods2

if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi

bootstrap_iso_id=`openstack image list -f json | jq -r '.[] | select(.Name == "'$name'-bootstrap.iso") | .ID'`

openstack volume create --size=2 --image=$bootstrap_iso_id --bootable $name-bootstrap-iso 
bootstrap_iso_vol_id=`openstack volume list -f json | jq -r '.[] | select(.Name == "'$name'-bootstrap-iso") | .ID'` 

openstack volume create --size=120  --bootable $name-bootstrap-volume
bootstrap_vol_id=`openstack volume list -f json | jq -r '.[] | select(.Name == "'$name'-bootstrap-volume") | .ID'`

openstack server create --flavor b2-30 --port $name-bootstrap --block-device uuid=$bootstrap_iso_vol_id,source_type=volume,destination_type=volume,disk_bus=ide,device_name=/dev/vda,volume_size=2,device_type=cdrom,boot_index=1 --block-device source_type=volume,uuid=$bootstrap_vol_id,destination_type=volume,device_name=/dev/hda,volume_size=120,boot_index=0 --security-group default --wait $name-bootstrap

master_iso_id=`openstack image list -f json | jq -r '.[] | select(.Name == "'$name'-master.iso") | .ID'`

for master in master-0 master-1 master-2; do
	openstack volume create --size=2 --image=$master_iso_id  --bootable $name-$master-iso 
	master_iso_vol_id=`openstack volume list -f json | jq -r '.[] | select(.Name == "'$name'-'$master'-iso") | .ID'`      

	openstack volume create --size=120  --bootable $name-$master-volume
	master_vol_id=`openstack volume list -f json | jq -r '.[] | select(.Name == "'$name'-'$master'-volume") | .ID'`

	openstack server create --flavor b2-30 --port $name-$master --block-device uuid=$master_iso_vol_id,source_type=volume,destination_type=volume,disk_bus=ide,device_name=/dev/vda,volume_size=2,device_type=cdrom,boot_index=1 --block-device source_type=volume,uuid=$master_vol_id,destination_type=volume,device_name=/dev/hda,volume_size=120,boot_index=0 --security-group default --wait $name-$master
done



