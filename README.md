# EKS-GoWebserver
*Combined repository for deploying a Go-app on an EKS cluster initialised through Terraform and managed with Helm. For a detailed breakdown of the implementation within the directory to support continued development and further customisation along with testing/deployment workflows, please see [docs](Docs/README.md).*

---
## Contents 

- [Pre-requisites](#pre-requisites)
- [Setup](#setup)
  - [Get the source code](#get-the-source-code)
  - [Configuring Terraform](#configuring-terraform)
  - [Create remote backend](#create-remote-backend-optional)
  - [Set up AWS access](#set-up-aws-access)
- [Infrastructure provisioning](#infrastructure-provisioning)
  - [The Modules](#the-modules)
  - [Resource creation](#resource-creation)
- [Deployment](#deployment)
  - [Updating Kubecontext](#updating-kubeconfig)
  - [Installing system services](#installing-system-services)
  - [Deploying application](#deploying-the-application)
  - [Testing the application](#testing-the-application)


## Pre-requisites

  - **Terraform** installed and available in your system's `PATH` (recommended version: 1.11.x). [&rarr;](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
  - **AWS CLI** v2+ is required to be installed and should be available in your system's `PATH`.  [&rarr;](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - **Helm** installed and available in your system's `PATH` (recommended version: 3.17.x). [&rarr;](https://helm.sh/docs/intro/install/)
  - **Kubectl** is recommended for checks/debugging and getting the endpoint of the app; AWS console is also viable. [&rarr;](https://kubernetes.io/docs/tasks/tools/)
  - **Docker** will be need to be installed and available for running the image locally if needed. [&rarr;](https://docs.docker.com/engine/install/)
  - A linux based machine is recommended and general non-tool based commands will assume a linux environment.

## Setup

1.  ### Get the source code
      - Clone the repository

        ```bash
            $ git clone git@github.com:Bh-an/EKS-GoWebserver.git

            $ cd EKS-GoWebserver
        ```
       or

      - Download the latest source code release (tar.gz) from [here](https://github.com/Bh-an/EKS-GoWebserver/releases/latest)
      - Extract the file
        ```bash
            $ curl -OL https://github.com/Bh-an/EKS-GoWebserver/archive/refs/tags/<RELEASE_TAG>.tar.gz

            $ tar -xvf <RELEASE_TAG>.tar.gz

            $ cd EKS-GoWebserver-<RELEASE_TAG>/
        ```
        latest release tag on time of writing - 'timeservice-1.0.6'
2. ### Configuring Terraform
      - Available configuration values:

        | Value                  | type          | default                                  | required |
        |------------------------|---------------|------------------------------------------|----------|
        | `region`               | string        | `"ap-south-1"`                           | false    |
        | `platform`             | string        | `"k8s"`                                  | false    |
        | `environment`          | string        | `"test"`                                 | false    |
        | `vpc_cidr`             | string        | `"10.0.0.0/16"`                          | false    |
        | `public_subnets_cidr`  | `list(any)`   | `["10.0.1.0/24", "10.0.2.0/24"]`         | false    |
        | `private_subnets_cidr` | `list(any)`   | `["10.0.101.0/24", "10.0.102.0/24"]`     | false    |
        | `cluster_name`         | string        | `"default_cluster"`                      | false    |
        | `instance_types`       | `list(any)`   | `["t3.small"]`                           | false    |
        | `nodegroup_name`       | string        | `"default_nodegroup"`                    | false    |
        | `capacity_type`        | string        | `"ON_DEMAND"`                            | false    |
        | `nodegroup_desired_size`| string       | `1`                                      | false    |
        | `nodegroup_max_size`   | string        | `4`                                      | false    |
        | `nodegroup_min_size`   | string        | `0`                                      | false    |
      - This contains a list of all the configurable values available within the implementation along with default values

      - Create a ```terraform.tfvars``` file for any values that you want to change (not required)

        ```bash
            # Sample terraform.tfvars file
            environment = "dev"
            cluster_name = "webservice_cluster"
            instance_types = ["t3.small","t3.medium"]
            nodegroup_desired_size = "2"
        ```

      - This file should exist in `terraform/`

      *NOTE: The currently available configurations are a bit lacking and should be inlcuded in improvements*

3. ### Create remote backend (*optional*)

      - Terraform now supports state locking within s3 itself and Dynamo DB locking is deprecated. As such both statefiles and locks will now exist within an s3 bucket. ([more info](https://developer.hashicorp.com/terraform/language/backend/s3))

      - You will first need to create an s3 in your aws account (same region), with the following configurations:

                Bucket type: General purpose
                Bucket name: <YOUR_BUCKET_NAME>
                Object Ownership: ACLs disabled
                Public Access: Block all
                Bucket Versioning: enabled
                Default encryption: Server-side encryption with Amazon S3 managed keys (SSE-S3)
                Bucket key: enable
      
      - Edit the `terraform/default.s3.backend` file:

        ```bash
            # default.s3.backend file
            bucket = "<YOUR_BUCKET_NAME>" 
            key    = "path/to/state/file.tfstate" # auto-created, should end in '.tfstate'
            region = "<YOUR_BUCKET_REGION>"
        ```

4. ### Set up AWS access

      - We will be setting up an IAM user that will be used by Terraform to query AWS for planning and creating the templated resources, as well as for pulling the cluster config to our local kube config.
      
        - This section assumes you already have access to aws console with an admin account. If you'd like to use the admin user itself and have credentials for it, skip to the section for configurinng aws cli credentials

        - Create a [new IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started-workloads.html) and name it 'terraform'. Follow the instructions to create and download access credentials for this user.Create a user group called 'provisioners' and attach the terraform user to it.

        - Create two [new policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create-console.html#access_policies_create-json-editor) named ```tf_create``` and ```tf_destroy``` using the two policy documents available in ```docs/policies/```. Attach these to the 'provisioners' group you created previously.

        > [!WARNING]  
        > The policies use the '*' wildcard to target resources. This is generally not recommended but because we are deploying everyhting together it is much easier. Please read and understand both the terraform and the permissions it is given. 

      - Configuring the CLI to use access credentials from the user, assumes you have the access ID and key for the user you want to set up as well as aws cli v2+ installed.

        - Configure aws profile for user:

          	```bash
            $ aws configure --profile terraform

            AWS Access Key ID [None]: <AWS_ACCESS_ID>
            AWS Secret Access Key [None]: <AWS_ACCESS_KEY>
            Default region name [None]: <AWS_REGION>
            Default output format [None]: json
            
            ```

        - Terraform, aws cli and other tools will now pull from the authectication chain that inlcudes the aws config file. To confirm usage of this profile, export the value:

            ```bash
            $ export AWS_PROFILE=terraform
            ```

        - Confirm user identity:

            ```bash
            $ aws sts get-caller-identity
            ```
          



## Infrastructure provisioning

1. ### The modules

      - Terraform will create the following infrastructure, defined broadly within these modules:

        <br>
        <details>
        <summary>Networking</summary>
        <br>
        > Virtual private cloud (VPC)
        <br>
        > Subnets: 2 public for load balancers, 2 private for nodes
        <br>
        > Gateways: NAT for private nodes, IGW for internet access and endpoints
        <br>
        > Routing: Route tables and associations for routing traffic within the subnets
        </details>
        <br>
        <details>
        <summary>Identity and Access management</summary>
        <br>
        > Policies: Data for AWS policies relating to Cluster and Nodegroups
        <br>
        > Roles: Cluster and Nodegroup roles and policy attachments to these roles
        </details>
        <br>
        <details>
        <summary>Cluster</summary>
        <br>
        > Controlplane: EKS resource for initialising cluster
        <br>
        > NodeGroup: Configs and launch templates for EKS nodes
        <br>
        </details>
        <br>
        <details>
        <summary>Open ID connector (OIDC)</summary>
        <br>
        > OIDC: ID and permission provider to service accounts within the cluster
        <br>
        > Cloud Controller: Role, policy and it's atatchment along with identity provided by OIDC
        <br>
        </details>

2. ### Resource creation

      - Move to `terraform/` and initialise Terraform with remote backend

        ```bash
            $ cd terraform/

            $ terraform init -backend-config=./default.s3.tfbackend
        ```
        if not using remote backend, just run ```terraform init```

      - Apply the infrastrcuture changes after reviewing them

        ```bash
            $ terraform apply
        ```
          > If everything looks good, approve the proposed changes

      - Note the outputs provided by terraform, they will be used later

        ```bash
            Apply complete! Resources: 28 added, 0 changed, 0 destroyed.

            Outputs:

            load_balancer_controller_role_arn = "<LOAD_BALANCER_ARN>"
            vpc_id                            = "<VPC_ID>"
        ```

## Deployment

1. ### Updating kubeconfig

      - Add the configuration and credentials for the newly created cluster

        ```bash
            $ aws eks --region <AWS_REGION>  update-kubeconfig --name <CLUSTER_NAME>

            Updated context arn:aws:eks:ap-south-1:774305577388:cluster/default_cluster in /home/bhan/.kube/config
        ```
        > Refer to `terraform/variables.tf` or `terraform/terraform.tfvars` for values

      - If your kubeconfig has multiple context, view them and switch to this EkS cluster

        ```bash
            $ kubectl config get-contexts

            $ kubectl config use-context <context-name>
        ```

2. ### Installing system services
      - Move back to project root 

        ```bash
            $ cd ..
        ```

      - Before we can deploy our app, we need to install the AWS load balancer controller which will allow us to create AWS native loadbalancer resources. ([more info](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html))

      - Install custom resource definitions used by the controller helm chart 

        ```bash
            $ kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

            customresourcedefinition.apiextensions.k8s.io/ingressclassparams.elbv2.k8s.aws created
            customresourcedefinition.apiextensions.k8s.io/targetgroupbindings.elbv2.k8s.aws created
        ```
        > Note: The command uses the kustomize (-k) flag which was only packaged within kubectl natively from v1.14.0 onwards.

      - Add the Helm repository for the controller

        ```bash
            $ helm repo add eks https://aws.github.io/eks-charts
        ```

      - The override values for the chart exist inside the file `helmfile.d/values/lb_controller_values.yaml`, some of which we will override. For a full list of available configurations see [here](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/README.md)

      - Change values in the `helmfile.d/values/lb_controller_values.yaml` file; for ```eks.amazonaws.com/role-arn```, ```clusterName``` and ```vpcId```to match your cluster.

        > Note: Value for cluster name is default_cluster if unchanged. Vpc id and load balancer arn are available in the terraform output. To get the values again, switch to the `terraform` directory and run:
          ```
              $ terraform output
          ```

      - Install the Helmchart in the kube-system namespace

        ```bash
            $ helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -f ./helmfile.d/values/lb_controller_values.yaml \
            -n kube-system


            NAME: aws-loadbalancer-controller
            LAST DEPLOYED: Sun Apr 27 22:00:22 2025
            NAMESPACE: kube-system
            STATUS: deployed
            REVISION: 1
            TEST SUITE: None
            NOTES:
            AWS Load Balancer controller installed!
        ```
        
      - Check if the controller pod is up and running

        ```bash
            $ kubectl get pods -n kube-system

            NAME                                            READY   STATUS    RESTARTS   AGE
            aws-load-balancer-controller-7d77966659-tt6g9   1/1     Running   0          1h
        ```

      - - Check if the controller webhook service is up and running

        ```bash
            $ kubectl get pods -n kube-system

            NAME                                                              READY   STATUS    RESTARTS   AGE
            aws-loadbalancer-controller-aws-load-balancer-controller-79lbrn   1/1     Running   0          98s
        ```

3. ### Deploying the application
      
      - Add the Helm repository for the application

        ```bash
            $ helm repo add timeservice https://bh-an.github.io/EKS-GoWebserver/
        ```

      - The override values for the chart exist inside the file `helmfile.d/values/timeservice_values.yaml`. For a full values file see [here](https://github.com/Bh-an/EKS-GoWebserver/blob/main/helmchart/timeservice/values.yaml)


      - Install the helm chart in a new namespace
        
        ```bash
            $ helm install timeservice timeservice/timeservice \
            --create-namespace -n webservices

              NAME: testservice
              LAST DEPLOYED: Mon Apr 28 11:50:39 2025
              NAMESPACE: webservices
              STATUS: deployed
              REVISION: 1
              NOTES:
              1. Get the application URL by running these commands:
              NOTE: It may take a few minutes for the LoadBalancer to be to be available.
              You can watch its status by running 'kubectl get --namespace webservices svc -w testservice-timeservice'
              export SERVICE_IP=$(kubectl get svc --namespace webservices testservice-timeservice --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
              echo http://$SERVICE_IP:80
        ```

    - Check if the application pods are up and running

        ```bash
           $ kubectl get pods -n webservices

            NAME                                      READY   STATUS    RESTARTS   AGE
            timeservice-87b76bf7c-cnccn   1/1     Running   0          13m  
        ```

    - Check if the service is up and running

        ```bash
            $ kubectl get svc -n webservices

            NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP                                                                      PORT(S)        AGE
            timeservice   LoadBalancer   172.20.17.178   k8s-webservi-timeserv-84f02ba240-13857ebaf0a236c3.elb.ap-south-1.amazonaws.com   80:31689/TCP   9m23s
        ```
        > Note: Even though the service might be up, the load-balancer in AWS can take a few minutes to create.

4. ### Testing the application

      - Get the external IP for for the service:

      ```bash
          export SERVICE_IP=$(kubectl get svc --namespace webservices timeservice --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
      ```

      - Send a request to the endpoint (http and port 80 is defualt here):

      ```bash
          $ curl $SERVICE_IP

          {"timestamp":"2025-April-28 06:30:17 UTC","ip":"14.194.165.182:54330"}
      ```

      *Note: You can also use your preferred REST tool (postman, restler etc.) by copying the external IP given by ```kubectls get svc -n webservices```, it's also the value stored in ```echo $SERVICE_IP```*



