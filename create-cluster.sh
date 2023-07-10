. ./env.sh

set -x

export name=digit1
export basedomain=geotec.xyz
export cidr=10.20.0

sh create-network.sh
sh create-dns.sh
sh create-image.sh
sh create-server.sh

sleep 600

dir=iso/$name

export KUBECONFIG=$dir/auth/kubeconfig

no=0
while [[ $no -lt 60 ]]; do 
	nb=`oc get nodes | grep -i ready | grep -v -i notready | wc -l`
	if [[ $nb -eq 3 ]]; then break; fi
	sleep 60
	let no=no+1
done

if [[ $no -eq 60 ]]; then echo "timeout with no master available"; exit 2; fi

sh end-cluster-creation.sh

