# DevOps_Project_using_Terraform_and_Helm

This repo contains the code required to deploy two containers in the `user` and `shift` namespace via `Helm Chart` into an `EKS Cluster`.

Within the `DevOps_Project_using_Terraform_and_Helm`, there are three separate folders

- [/terraform](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/terraform/modules/myapp) contains the Terraform module that provisions the Helm Chart into an EKS Cluster.
- [/helm](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/helm/myapp) contains the Helm Chart with the Kubernetes manifest files
- [/deployment](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/deployment/k8sapp) deploys the Terraform module under `/terraform/module/myapp` across multiple environments.

## Prerequisites

I have set up my Kubernetes cluster using AWS EKS and provisioned it through Terraform. [You can find the link to my Terraform EKS Cluster module](https://github.com/arulsophiya/AWS_EKS_Terraform_Module)

## 1) Deploy containers via Helm and Terraform

Once the cluster is up, I deployed two different containers of image nginx and httpd by leveraging the Helm provider in Terraform.

`To summarize, the Helm chart does the following:`

- Creates a deployment of image `nginx`, a service which forwards the requests to the nginx pod and a HorizontalPodAutoscaler to scale based on the load in the `user` namespace.
- Creates a deployment of image `httpd`, a service which forwards the requests to the nginx pod and a HorizontalPodAutoscaler to scale based on the load in the `shift` namespace.
 
[/terraform/module/myapp](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/terraform/modules/myapp) module provisions a helm resource referencing the helm chart under [/helm/myapp](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/helm/myapp). The configuration looks like this.

```tf
resource "helm_release" "app" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  chart            = "../../../helm/myapp"
  dynamic "set" {
    for_each = local.app_values
    content {
      name  = set.key
      value = set.value
      type  = "string"
    }
  }
}
```

#### Output :
```
PS C:\Users\Sophiya\Desktop\github\kubernetes project\deployment\k8sapp\dev> kubectl get all -n user
NAME                                   READY   STATUS    RESTARTS   AGE        
pod/user-deployment-8684c6cf78-pjjvk   1/1     Running   0          24s        

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/user-service   ClusterIP   172.20.245.55   <none>        8080/TCP   24s

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/user-deployment   1/1     1            1           24s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/user-deployment-8684c6cf78   1         1         1       24s

NAME                                           REFERENCE                    TARGETS                       MINPODS   MAXPODS   REPLICAS AGE
horizontalpodautoscaler.autoscaling/user-hpa   Deployment/user-deployment   <unknown>/1k, <unknown>/70%   1         10        1        24s
```

```
PS C:\Users\Desktop\github\kubernetes project\deployment\k8sapp\dev> kubectl get all -n shift
NAME                                    READY   STATUS    RESTARTS   AGE
pod/shift-deployment-866cdc5df6-8wzsq   1/1     Running   0          2m36s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/shift-service   ClusterIP   172.20.13.171   <none>        8080/TCP   2m36s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/shift-deployment   1/1     1            1           2m36s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/shift-deployment-866cdc5df6   1         1         1       2m36s

NAME                                            REFERENCE                     TARGETS                MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/shift-hpa   Deployment/shift-deployment   <unknown>/1k, 1%/70%   1         10        1          2m36s

```

## 2) Scale the deployment based on CPU

I have used `HorizontalPodAutoscaler` to auto-scale the pods based on CPU Utilization.
Below is the HPA file that scales up when the CPU usage reaches 70% and scales down during low traffic.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.hpa.name }}
  namespace: {{ .Values.hpa.namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.hpa.ref }}
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 3) Rolling Update Deployments and Rollbacks

Configure the deployment file with the `RollingUpdate` strategy under `spec` to ensure that pods are updated in a rolling update fashion.

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
```
To `rollback` to the previous deployment, modify the configuration files in Terraform to match the previous version.

## 4) Restricted Access to the cluster using IAM and RBAC

To allow others to gain limited access to your cluster:

- Create an `IAM role` with the required permissions and add a trust relationship for the account to assume the role.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::accountId:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
```

- Create `Role` and `Role Binding` objects to enable access on specific kubernetes objects.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: user-deployment-role
  namespace: user
rules:
  - apiGroups:
      - ""
      - extensions
      - apps
    resources:
      - deployments
      - replicasets
      - pods
    verbs:
      - create
      - get
      - list
      - edit
      - patch
      - watch
      - rollout
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-deployment-rolebinding
  namespace: user
roleRef:
  apiGroup: ""
  kind: Role
  name: user-deployment-role
subjects:
  - kind: User
    name: dev
    apiGroup: ""
```

The `user-deployment-role` allows the user `dev` to perform deployment and rollback actions only in the `user namespace`.

- Edit the `aws-auth ConfigMap` under `mapRoles` section to include the `IAM role arn`, `Kubernetes role name` and `Kubernetes user`.

```yaml
mapRoles: |
  - rolearn: arn:aws:iam::accountId:role/EKSAssumeRole
    username: dev
    groups:
      - user-deployment-role
```

Now, anyone who assumes the EKSAssumeRole will only have the permissions to perform `deployment and rollback actions` within the `user` namespace.

## 5) Deployment across multiple environments

For deployment, I have created a [deployment](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/deployment/k8sapp) folder. This directory contains subdirectories for multiple environments such as dev, prod and stage.

Each environment contains terraform configuration files which will invoke the Terraform module [/terraform/module/myapp](https://github.com/arulsophiya/DevOps_Project_using_Terraform_and_Helm/tree/main/terraform/modules/myapp) with the different values based on the environment.

```tf
module "user-app" {
  source           = "../../../terraform/modules/myapp"
  cluster_endpoint = var.cluster_endpoint
  cluster_ca_cert  = var.cluster_ca_cert
  cluster_name     = var.cluster_name
  region           = var.region
  name             = local.user_values.name
  namespace        = local.user_values.namespace
  deployment_name  = local.user_values.deployment_name
  deployment_label = local.user_values.deployment_label
  container_name   = local.user_values.container_name
  image            = local.user_values.image
  port             = local.user_values.port
  service_name     = local.user_values.service_name
  service_port     = local.user_values.service_port
  hpa_name         = local.user_values.hpa_name
  hpa_ref          = local.user_values.hpa_ref
}
```

## 6) Auto Scale the deployment based on network latency

To scale the deployment based on other metrics like network latency, we have to make use of the `Custom Metrics API` in kubernetes. This API exposes custom metrics from third party tools like `Prometheus` which can be used by `HorizontalPodAutoScaler` to make scaling decisions.

In order to implement this:

- We need to install two components. `Prometheus` and `Prometheus Adaptor`
- The Application sends the metrics such as `application response time`, `number of active connections` to Prometheus.
- The `Prometheus Adapter` retrieves these metrics from Prometheus and makes them available through the `Custom Metrics API`. 
- The `HorizontalPodAutoScaler` then utilizes this API to access the metrics for scaling.

Configure the HorizontalPodAutoScaler to include the custom metrics.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.hpa.name }}
  namespace: {{ .Values.hpa.namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.hpa.ref }}
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: application-response-time
      target:
        type: AverageValue
        averageValue: 1k
```
Now the HorizonPodAutoscaler can scale based on `CPU Utilization` and `Network Latency`. 
