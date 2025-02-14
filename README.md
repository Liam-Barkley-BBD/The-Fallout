# The-Fallout
It is a post-apocalyptic world where a nuclear fallout has wiped all food from the earth, except for BEANS. This database system manages shelters, survivors and bean supply between shelters to ensure no one goes hungry. 

## Setting up docker

1. Install docker/podman

2. Set up docker image:
```
podman compose up -d
```

3. Grab the container id
 
```
podman ps
```
```
podman exec -it <container_id> bash
```

4. Set up AWS CLI
```
aws configure
``` 

5. Run Terraform
```
terraform init
```
```
terraform apply --auto-approve
```

Misc: Destroying docker

```
podman compose down -v
```