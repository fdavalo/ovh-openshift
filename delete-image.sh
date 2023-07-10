if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi

dir=iso/$name

rm -rf $dir

openstack image delete $name-bootstrap.iso
openstack image delete $name-master.iso
openstack image delete $name-worker.iso


