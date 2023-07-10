set -x

#name=rhods2
#basedomain=geotec.xyz

if [[ "$name" == "" ]]; then echo "name not set"; exit 1; fi
if [[ "$basedomain" == "" ]]; then echo "base domain not set"; exit 2; fi
if [[ "$cidr" == "" ]]; then echo "cidr base not set"; exit 2; fi

dir=iso/$name

rm -rf $dir
mkdir -p $dir

sed -e "s/@name@/$name/g" -e "s/@baseDomain@/$basedomain/g" templates/install-config.yaml > $dir/install-config.yaml
sed -i -e "s/@cidr@/$cidr/g" $dir/install-config.yaml

./iso/openshift-install create ignition-configs --dir $dir

coreos-installer iso customize iso/rhcos-4.13.0-x86_64-live.x86_64.iso --dest-ignition $dir/bootstrap.ign --dest-device /dev/vda -o $dir/bootstrap.iso 
coreos-installer iso customize iso/rhcos-4.13.0-x86_64-live.x86_64.iso --dest-ignition $dir/master.ign --dest-device /dev/vda -o $dir/master.iso 
coreos-installer iso customize iso/rhcos-4.13.0-x86_64-live.x86_64.iso --dest-ignition $dir/worker.ign --dest-device /dev/vda -o $dir/worker.iso 

openstack image delete $name-bootstrap.iso
openstack image delete $name-master.iso
openstack image delete $name-worker.iso

openstack image create --disk-format iso --file $dir/bootstrap.iso --private $name-bootstrap.iso
openstack image create --disk-format iso --file $dir/master.iso --private $name-master.iso
openstack image create --disk-format iso --file $dir/worker.iso --private $name-worker.iso

