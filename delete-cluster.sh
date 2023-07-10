. ./env.sh

set -x

export name=digit1
export basedomain=geotec.xyz
export cidr=10.20.0

sh delete-server.sh
sh delete-image.sh
sh delete-network.sh
