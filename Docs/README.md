# Project docs

## Contents

- [Introduction](#introduction)
- [The application](#the-application)
  - [Language](#language)
  - [Code Logic](#code-logic)
  - [Package structure](#package-structure)
  - [Containerisation](#containerisation)
  - [Local image testing](#testing-image-locally)
- [Terraform](#terraform)
  - [The modules](#the-modules)
  - [File structure](#file-structure)
  - [Improvements](#improvements)
- [Deployment](#deployment)
  - [Helmchart](#helmchart)
  - [Service loadbalancer](#service-loadbalancer)
  - [Packaging](#packaging)
- [Continuous Integration and Deployment](#continuous-integration-and-deployment)
  - [Workflows](#workflows)
  - [Helmfile](#helmfile)
  - [System charts](#system-charts)
  - [Secrets and Variables](#secrets-and-variables)
- [Thoughts and retrospective](#thoughts-and-retrospective)

## Introduction

The project focuses on 4 main areas of work, which also define how this document is structured. The repo aims to provide a way of cohesively bring together these aspects to provide a unified version control where software can be developed and deployed to the cloud. It's divided into the following aspects:
    
- The application: Language, code logic, package structure and containerisation.
- Terraform: Modules, file structure, improvements
- Deployment: Helmchart, Service loadbalancer, packaging
- CI/CD: Workflows, Helmfile, System charts

## The application

- ### Language
  Go was chosen for the project due to a few reasons:
    - It can be run single static executable binary, does not need any runtime environments to run within containers.
    -  It's compiled which gived it an edge over interpreted languages and provides better performance and resource efficiency.
    - Great standard libraries like `net/http`, no external dependencies are needed for the usecase provided.
    - Go's native struct collection is very good for response modelling.
    - I have been learning it recently and wanted to inlcude it in the project.

- ### Code logic

    - IP and Timezone data is captured from the headers of incoming http requests.
    - `X-Forwaded-For` for client IP which included by default in http requests.
    - `X-Timezone` for client timezone which is not included by default but can be added to the header. The timezones are expected to have [TZ identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) values. If not included, it defaults to UTC time
    - Strunt and json encoding is used to define response models

- ### Package structure 
    Packaging and file structure follows a format that expects further devlopment.

            ```bash
                go-server
               ├── cmd
               │   └── go-server
               │       └── main.go
               ├── config.json
               ├── Dockerfile
               ├── go.mod
               └── internal
                   ├── config
                   │   └── config.go
                   ├── handlers
                   │   └── defaultHandler.go
                   ├── models
                   │   └── defaultModel.go
                   └── utils
                       ├── ipUtils.go
                       ├── ipUtils_test.go
                       ├── timeUtils.go
                       └── timeUtils_test.go
            ```
  - `cmd/go-server:` Contains the main entrypoint for the webserver. As well as url path associations with their respective handler
  - `internal/config:` Contains the config loader for the server configurations. Additional configurations for RDS, S3 etc should be loaded from here
  - `internal/handler:` Contains the handler for different url paths
  - `inernal/models:` Contains response/request models for different HTTP
  - `internal/utils:` Code logic primarily lives here and it called by different handlers as needed 
  - `go.mod:` Manages imported libraries and go version. Is usually paired with `go.sum` but is not needed here since no external libraries are used
  - `config.json:` Contains config values like listener port

- ### Containerisation

    - Managed through a `Dockerfile`
    - To keep the image size small, image is built in a multi-stage format.  
    - The build command used is as follows: 
        ```bash
            RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
            -ldflags="-w -s -extldflags '-static'" -o go-server \
            ./cmd/go-server/main.go
        ```
        > `CGO_ENABLED=0` ; disables calling C-code
        
        > `GOOS=linux` ; redundancy in case of different builder, builds for linux

        > `GOARCH=amd64` ; binary compatibility for x86-64

        > `-ldflags="-w -s` ; compile linker flags for excluding degub info and symbol table

        > `-extldflags '-static'` ; used to ensure static binaries
    - The base image used for the final build is 'distroless' by GCR which is preferred over 'scratch' because it allows some runtime dependencies; especially for our usecase the ability to set user based ownership and execution. 
    - The application is set to run as a non-root user `1001`.
    - The image is hostedon Github container registry and is associated with this repo, it's available [here](https://github.com/Bh-an/EKS-GoWebserver/pkgs/container/eks-gowebserver)

- ### Testing image locally 

    - Docker should be installed and available on the CLI

    - Run the image:
        ```bash
        $ docker run --name test -p 8080:8080 -d ghcr.io/bh-an/eks-gowebserver:latest

        Unable to find image 'ghcr.io/bh-an/eks-gowebserver:latest' locally
        latest: Pulling from bh-an/eks-gowebserver
        51c1b6699f43: Already exists
        2e4cf50eeb92: Already exists
        4e9f20d26c87: Already exists
        0f8b424aa0b9: Already exists
        d557676654e5: Already exists
        d82bc7a76a83: Already exists
        d858cbc252ad: Already exists
        1069fc2daed1: Already exists
        b40161cd83fc: Already exists
        3f4e2c586348: Already exists
        80a8c047508a: Already exists
        bc49b1b9f5cc: Pull complete
        5860d2f7436d: Pull complete
        06b3e1f99d49: Pull complete
        Digest: sha256:c83c467a23964e1e4ea04cb14dade8f7aada1205fd1088b444a0083be2b65b8b
        Status: Downloaded newer image for ghcr.io/bh-an/eks-gowebserver:latest
        f2da3823132f38fdc1cdda99d47ce99d249edecf6d80b7626e495b619df22bc7
        ```
    -  Curl the endpoint:
        ```bash
        $ curl localhost:8080/

        {"timestamp":"2025-April-28 07:25:32 UTC","ip":"172.17.0.1:39666"}
        ````     

## Terraform

- ### The modules

    - **Networking**:

        **A VPC :** All EKS components exists within this private cloud in AWS

        **Subnets :** 2 public for loadbalancers and 2 private for nodes
        > Note: These subnets need to be tagged as 

        ```"kubernetes.io/role/elb(internal-elb for private subnets)" = "1"``` 
        ```"kubernetes.io/cluster/${var.cluster_name}" = "owned"```

        **Gateways :** IGW and a NAT gateway for nodes and load balancers to reach the internet, pulling images, running updates webhooks etc. 
        **Routing :** Routing tables for both subnets and we will use default SGs to allow full communication between k8s components, they should be secured on k8s level.
        ****

    - **Identity and Access Management**:

         **Policies :** Pulls the data for pre-defined aws managed policies for allowing cluster and node related activities. Specifically- 

       
        > ```AmazonEKSClusterPolicy``` : Cluster policy for EKS controlplane.

        > ```AmazonEKSServicePolicy``` : Controlplane policy to allow managing service components.

        >```AmazonEKSWorkerNodePolicy``` : Node policy for EKS worker nodes.

        > ```AmazonEKS_CNI_Policy``` : Policy to set up container networking between nodes. 

        > ```AmazonEC2ContainerRegistryReadOnly``` : Policy to allow Nodes to pull images from the amazon ECR (for Nodeadm, kubelet etc).

        > ```AssumeRole``` policies for EKS (service) and Nodes (EC2)
       

        **Roles :** IAM roles for cluster and nodes along with policy attachement for the aformentioned policies.

    - **Cluster components:** 

        **Cluster :** EKS controlplane resource for initialising a cluster

        **Node Groups :** Contains the configurations for setting up the Node Auto-Scaling group along with launch templates for nodes

        **Launch Template :** Launch template for setting up the nodes.

        > EKS automatically asigns the EKS nodes the AL2023 linux image which uses nodeadm in the bootstrap.sh EC2 script. Since our nodes are not fully managed by aws, we need to pass nodeadm cluster details for the node to connect to the cluster. [Ref. [link](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) ; [link](https://aws.amazon.com/blogs/containers/amazon-eks-optimized-amazon-linux-2023-amis-now-available/)]

        *Note: A better implementation would be to allow user managed cluster version and amis for the EKS controplane and nodes*

    - **Open ID connect provider:**

        **The OIDC provider :** Creates and attaches an OIDC provider to the cluster. Cluster service roles can no have IAM roles created and provided for them through this using annotations.
 
        **Cloud controller :** OIDC created IAM role for and associated permissions the aws cloud controller identity used by the load balancer controller installed later in the project. 

- ### File Structure

    - **Modular components :** Reusable modules for different aspects of the setup. They are clearly seperated for ease of further work and base modules like networking and iam can be resused for multiple downstream ones.

    - **Variables & Outputs :** variables.tf and outputs.tf are clearly defined and used within modules to allow passing on and intaking values from different modules. Allows for centralised control over all variables used within terraform at root directory and from easy override from a single ```.tfvars``` file.

    - **Caller :** All the modules are called with dependency control from the ```/terraform/main.tf``` file which also contains the proviser and backend configuration block.
    
        *Note: The backend configuration is filled through the ```/terraform/default.s3.tfbackend``` file*

- ### Improvements

    - **Workspaces :** Including workspace support in how the configuration piping into the modules is setup to allow deployment into different environemnts through the same underlying config

    - **Added configuration options :** As discussed above, the currently available configs are bare, things like more node groups for workload types, manual ami management, sepcifying cluster version for kubernetes etc.

    - **Tighter isolation :** For production enviroments, network isolation within the VPC needs work through custom SGs and ACLs

## Deployment

- ### Helmchart:

    - The application is deployed through a Helmchart, which contains all the kubernetes resources neded to install the application onto our cluster and making it available to the internet.

    - Contains Deployment, Service, ServiceRole and more
        > Note: The Helmchart was created using the helm cli tool and further modified to deploy our application. As such it contains a lot of configuration options (HPA, Ingress etc) that have been disbaled but are available and can be used. Refer to  ```/Helmchart/Values.yaml```

- ### Service Loadbalancer:

    - By default kubernetes only supports Classic loadbalancers for service type resources. This provisioning is handles by the cloud-controller packaged into kubernetes. 

    - However for our purposes, we need a network load balancer because our application needs the ip to be preserved. For this we need to install the aws-load-balancer controller, which adds CRDs for the following aws resources to the cluster along with the associated load-balancer service:

        > ```Application LoadBalancer```: Available as an "Ingress" resource (layer 7)

        > ```Network LoadBalancer```: Available as an "Service" resource (layer 4)

    - To configure these load balancers within the k8s yamls itself, we can tell the aws-loadbalancer-controller what to do by using annotations.

        ```bash
            service:
            externalTrafficPolicy: Local
            type: LoadBalancer
            port: 80
            targetport: 8080
            annotations: {
                service.beta.kubernetes.io/aws-load-balancer-type: 'external',
                service.beta.kubernetes.io/aws-load-balancer-scheme: 'internet-facing',
                service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: 'ip',
                service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: 'preserve_client_ip.enabled=true',
                service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules: 'false'
            }
        ```

         > ```service.beta.kubernetes.io/aws-load-balancer-type: 'external'```

        ^ Tells the controller it will be routing external traffic

         > ```service.beta.kubernetes.io/aws-load-balancer-scheme: 'internet-facing'```

        ^ Schema type for the load balancer

         > ```service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: 'ip'```

        ^ Targets pods, ```instance``` will target nodes

         > ```aws-load-balancer-target-group-attributes: 'preserve_client_ip.enabled=true'``` 

        ^ Preserves the ips of client requests

         > ```aws-load-balancer-manage-backend-security-group-rules: 'false'```

        ^ Disables SG creation for each service. Having seperately managed SGs will stop terraform from being able to destroy the VPC created through it.

    - Read about more of these annotations [here](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/service/annotations/#subnets) 

- ### Packaging

    - The application Helm chart is packaged and made avaiable as a release through github's pages functionality for this repository.

    - The [chart-releaser](https://github.com/helm/chart-releaser-action) action is used to build and maintain the index for the page which transform it into a helm reposiroty.

## Continuous Integration and Deployment

For the puposes of this project, everything is built into [Gitchub Actions](https://github.com/features/actions) workflows. Tests and dry runs are triggered by pull requests to ```main``` and the CI/CD workflows are triggered  once changes are merged into main.  

- ### Workflows

    - **Checks.yaml**

        - Detects changes in application code, terraform, Helmchart and Deployment configurations; trigger appropriate jobs based on these, which inlcude:

        - Run tests for Go app and test-build the image using the Dockerfile. Adds a comment with new expected image version.

        - Generate terraform plan and display it in a comment on the PR along with the expected infrastrcuture version.

        - Lint the Helmchart and validate it.

        - Do a check of deployment configs and dry-run those changes as new deployment releases. Done through ```helmfile diff```

        ![Checks.yaml](images/ghactions_checks.png?raw=true "Title")

    - **Integration.yaml**

        - Detects changes in application code and helmchart, running appropriate jobs.

        - Application image is built and pushed to the Github container registry (GHCR) which is associated to this github repo, Comment is added to merged PR regarding the versioning info.

        - Helmchart's version is updated and a new github release is pushed. The chart released is managed on the ```helm-release``` branch from which it's github page based helm repo exists.

        ![Integration.yaml](images/ghactions_integration.png?raw=true "Title")
        ![build_page_release.yaml](images/ghactions_helmrelease.png?raw=true "Title")

    - **Deployment.yaml**

        - Detecs changes in infrastrcuture or the k8s service deployments, Running jobs as needed.

        - The terraform action checks for any changes within the plan that was run during the Checks workflow and current plan, applying the changes if they match.

        - Helmfile is used to deploy any changes, updating the deployed app version or the Chart version used for deployemnt. More on helmfile below

        ![Deployment.yaml](images/ghactions_deploymentinfra.png?raw=true "Title")
        ![Deployment.yaml](images/ghactions_deploymentcharts.png?raw=true "Title")

- ### Helmfile 

    - Very useful for managing the deployment of multiple Helm charts onto k8s clusters. Open-source project still in pre-release (v 0.x.x) but works very well for our usecase: managing multiple aspects of the project within a single repository.

    - The ```diff``` plugin helps helmfile check deployment yamls against deployed resources, showing the changes if any. This helps in checking changes before they're applied

    - Labels can be used to selectively deploy helmfiles (collections of helmcharts). The CI/CD here uses the component label to differentiate and apply ```system``` or ```application ``` changes to the cluster.

    - The configs in contained in ```helmfile.d``` on the main branch govern what is currently deployed on the cluster. Both application and chart versions 

    - Currently ```helmfile.d``` has two helmfiles ; ```system.yaml``` for system deployments and ```app.yaml``` for app deployments.

- ### System Charts

    - This is for system components that you need for functional aspects of the cluster. Can inlcude logging, controllers, metrics etc. We have installed the aws-loadbalancer-controller helmchart for provisioning aws loadbalancers.

    - The chart values overriden for our purposes are:
         
         - The lb controller role defined by our OIDC provider
         - The cluster name
         - VPC id for the cluster

         *more on the available values [here](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/values.yaml)* 

    - Only charts existing in ```helmfile.d/system.yaml``` are deployed in the cluster.

- ### Secrets and variables

    - AWS access keys and Github tokens were used in the workflows, safely through the use of repository secrets and variables.

    - Terraform and Helmfile commands were run through aws IAM user accounts with appropriate permissions. 
    *Note: For the purposes of this project a single account was used, it is highly recommended to have multiple accounts with need only access for all aspects of your pipeline*
    
    




## Thoughts and retrospective

- **The application**
    
    I have been learning Go the past few months and it was a really fun putting that to use here. The language feels like a very good mix of C and Java plus something new and has been fun to work with. The usecase could have been a little harder but I'm looking forward to developing something in Go on my own as well.

- **Terraform**

    I thought about pulling from the official terraform modules for EkS and building on top of that but ultimately decided to write everything myself. Configuring the nodes to join the cluster saw me looking at a lot of documentation, due to their hybrid nature. Making it looks neat probably took me longer than I wanted and i think the configurable values are a bit lacking in number.

- **Deployment**

    Took the decision to use Helmchart because i wanted the app to be easier to use on EKS. Services and other dependencies for making it avaialble could be configured and contained within a single deployer. Controllers are one of my favourite things within kubernetes getting familiar with the aws-loadbalancer-controller project was a good read.

- **Continuous Integration and Deployment**

    Honestly, the most time consuming part of the entire project. Should have used a local tester for Github Actions, i foind this one. Will definitely use one if I have to work with actions again. Major challeges came mostly from the fact that i wanted to do everything from a single repo. Ideally the application code, the helmchart and the infrastrcuture would benefit from being in seperate repos allowing much more robust workflows. The current setup needs a few guardrails regarding how development and deployment should be handled and can fail (although not catastrophically) if actions outside these guardrails happen. Would also want




    
