# Adding the possiblity to use ingress controller

## Objective

For now, if we want to access to an application installed on the cluster,
we have these solutions:
* Using the kubectl proxy
* Using the kubectl port-forward
* Using a service of type NodePort

All these methods are not really conveniant for the user.
It would be more interesting that he can access to the app using these ways for example:
* myApp.clusterUrl
* clusterUrl/myApp

To do this, we will install an ingress controller.

## Description

Before installing an ingress controller. we will need to add a clusterUrl.
To do this, we need a unique entry point to the cluster. 
We don't have this entry point yet. 
We will need to add a load balencer. 
We will use `MetalLB` which is easy to install.

## Install the Nginx Ingress Controller

Many tools can be used for the ingress controller :
* nginx
* nginx plus
* traefik
Nginx seems to me the one with the best documentation.
And it install everything in a specific namespace. 
So it is easy to uninstall this ingress-controller if we with.
But theres is two Nxing Controller:
* One developping by then Nginx team. You can find the documentation [here](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/)
* One developping by the Kubernetes team. You can find the documentation [here](https://kubernetes.github.io/ingress-nginx/)
Different between both can be found [here](https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/nginx-ingress-controllers.md)
I choose the Kubernetes version because the the install is easyer.
It is also easier to manage ingress resource between different namespaces.

To install it : 
```shell script
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml
```
Then we will add a service of type loadBalencer.
```shell script
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/cloud-generic.yaml
```
To check if the ingress controller pods have started, run the following command:
```shell script
kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx --watch
```
Once the operator pods are running, you can cancel the above command by typing Ctrl+C. Now, you are ready to create your first ingress.

Now let's check the service: 
```shell script
kubectl get svc -n ingress-nginx
```
You should have a result like this:
```shell script
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx   LoadBalancer   10.105.44.159   <pending>   80:31695/TCP,443:30977/TCP   11h
```
We will need an external IP to access the ingress controller. 
But, it won't come becaude there is no load balancer

## Setup the load balencer.

To install the `MetalLB` load balancer.
```shell script
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
```
You can find the documentation [here](https://metallb.universe.tf/).

Then we will need to configure `MetalLB` using a `ConfigMap`. 
This ConfigMap will set a rang of public IP. 
Each service of type `LoadBalancer` will now have an External-IP in this range.
1. We will need to find which range of IP address. 
Only a range of 1 IP address will be e enough in our case.
But to be safer in case of future need we can make a range of 10 IP addresses
Run:
```shell script
kubectl get node -o wide
``` 
You should obtain e result like this:
```shell script
NAME                   STATUS   ROLES    AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION               CONTAINER-RUNTIME
kmaster.example.com    Ready    master   3d12h   v1.17.3   172.42.42.100   <none>        CentOS Linux 7 (Core)   3.10.0-957.12.2.el7.x86_64   docker://19.3.6
kworker1.example.com   Ready    <none>   3d12h   v1.17.3   172.42.42.101   <none>        CentOS Linux 7 (Core)   3.10.0-957.12.2.el7.x86_64   docker://19.3.6
kworker2.example.com   Ready    <none>   3d12h   v1.17.3   172.42.42.102   <none>        CentOS Linux 7 (Core)   3.10.0-957.12.2.el7.x86_64   docker://19.3.6
```
Look the Internal `INTERNAL-IP` addresses. In my case, all addresses are in the range `172.42.42.xxx`.
I will need to choose a subset of 10 addresses in this range. 
For example a range from `172.42.42.200` to `172.42.42.210`.
Now let's modifie the file loadbalancer/metalLB-configmap.yml 
to change the field `address-pools.addresses`.
For example in my case this file look like this:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.42.42.200-172.42.42.210
```
Then let's create the `ConfigMap`.
```shell script
kubectl create -f loadbalancer/metalLB-configmap.yml
```
Now let's look the result for the Ingress Controller service.
```shell script
kubectl get svc  -n ingress-nginx
```
You should now have an `EXTERNAL-IP`.
```shell script
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx   LoadBalancer   10.105.44.159   172.42.42.200   80:31695/TCP,443:30977/TCP   12h
```
In my case, now I would be able to access to my cluster using the IP address: `172.42.42.200`.
We don't have DNS server, so we will use the file /etc/hosts to add a dns name.

Add this line to the file `/etc/hosts`.
```shell script
172.42.42.200 kubernetes.example.com kubernetes
```
Now we can access the cluster using the url : `kubernetes.example.com`.
But we don't have application and neither route. 
So let's add with an example.

## Testing the ingress controller with an example.
To test our cluster, we will deploy 3 application: 
* A simple Nginx in the `ingress-test-1` namespace
* A simple 'blue' app showing a web page with the content 'I am BLUE' in the `ingress-test-1` namespace
* A simple 'green' app showing a web page with the content 'I am GREEN' in the `ingress-test-2` namespace

The objective will be to acces this services using these urls:
* `http://kubernetes.example.com/nginx`
* `http://kubernetes.example.com/blue`
* `http://kubernetes.example.com/green`

You can check that all these urls are not working for now.

1. Let's start by craate the namespaces
```shell script
kubectl create -f ingress/samples/namespaces/
```
2. let's deploy the applications.
```shell script
kubectl create -f ingress/samples/deployments/ 
``` 
Now, we will have to create an `Ingress` resources to indicate to kubernetes the routes.
For the nginx app. We want that the `http://kubernetes.example.com/blue` is routed to the `nginx-svc` on port 80.
This will look like this:
```shell script
spec:
  rules:
    - host: kubernetes.example.com
      http:
        paths:
          - path: /nginx
            backend:
              serviceName: nginx-svc
              servicePort: 80
```
With the header, the file look like this.
```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-test-1
  namespace: ingress-test-1
  annotations:
    # use the shared ingress-nginx
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
    - host: kubernetes.example.com
      http:
        paths:
          - path: /nginx
            backend:
              serviceName: nginx-svc
              servicePort: 80
```
But this won't work. In this way. the `nginx-svc` service will be called in this way : 
`nginx-scv:80/nginx`. Expected was this: `nginx-scv:80`.
We need to remove the path `/nginx`.
To do that we will use regex:
```yaml
- path: /nginx(/|$)(.*)
```
And using annotation: 
```yaml
    nginx.ingress.kubernetes.io/rewrite-target: /$2
```
So the file look like this: 
```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-test-1
  namespace: ingress-test-1
  annotations:
    # use the shared ingress-nginx
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - host: kubernetes.example.com
      http:
        paths:
          - path: /nginx(/|$)(.*)
            backend:
              serviceName: nginx-svc
              servicePort: 80
```
We can add another path for the `blue-svc`. Look the file: `ingress/samples/ingress/ingress-test-1.yml`.
Let's deploy our new `Ingress` Resource.
```yaml
kubectl create -f ingress/samples/ingress/ingress-test-1.yml
``` 
And chech that the urls `http://kubernetes.example.com/nginx` and `http://kubernetes.example.com/blue`
have the expected behavior.

The file `kubectl create -f ingress/ingress-test-2.yml` configure the route for the `green`
application in the `ingress-test-2` namespace:
```yaml
kubectl create -f ingress/samples/ingress/ingress-test-2.yml
```
And chech that the urls `http://kubernetes.example.com/green`
have the expected behavior.
