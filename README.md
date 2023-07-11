# ovh-openshift

Here are the source to create/delete/scale a cluster Openshift on ovh

prerequisites : 
   - install oc cli (to check cluster node status)
   - install openstack cli (to create objects on ovh, except dns)
   - install coreos-installer (for iso ignition update)
   - fetch openshift-installer and coreos live iso (openshift cluster creation)
   - fetch openrc.sh from ovh user (for the specific region) : credentials for openstack on ovh
   - fetch application id+secret+customer token on ovh for dns modification (put in env.sh)
   - pip install ovh (for dns update)
   - add openshift pull secret and ssh public key on templates/install-config.yaml

parameters : 
   - set three variables before dealing with a cluster (creation, deletion, scale) : 
        - export name=cluster1   (name of the openshift cluster)
        - export basedomain=toto.com   (dns domain that must be owned on ovh)
        - export cidr=10.20.0  (10.20.0.0/24 for machine network and loadbalancers)

   - source env.sh (wich will source openrc.sh)

   - execute create-cluster.sh, delete-cluster.sh with no parameters (env vars only)

   - execute add-worker.sh <flavor>, 
        - flavor can be b2-15, ... t1-90, ... depending on the need

scripts:
   - sh create-cluster.sh to create a 3 node cluster on ovh (upi mode)
        - sometimes, time to get the ovh dns records available can be longer than expected and may affect the bootstrap of the cluster

   - sh add-worker.sh to add another worker with specific flavor (t1-90 with gpu)

   - sh delete-cluster.sh to remove all ovh components (not the dns)

comments:
   - terraform could be a better way to handle retry, etc but was not able to make it work for now with ovh, could re try it later
   - scripts could be embedded in ansible playbooks    
   - available to explain the scripts and give help for debugging
