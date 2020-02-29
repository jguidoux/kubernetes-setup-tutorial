# Deploying an empty single master node Kubernetes cluster using Ansible

## Description

This one master node cluster is deployed using :
* Vagrant to créate Centos virtual machine on Virtual box
* Ansible to deploy kubernetes en these vms.

But Vagrant is just here to create easily a cluser for tests. 
The main idea is to be able to deploy kubernetes on existing machines. 
To do this use the Ansible playbooks on ` vagrant/ansibleFiles/` directory.
It should be easy to change modify these Ansible playbooks to be adapt on your contexts.
These plàybook are made to work on Centos7. But it is possible to adapt them to work on an other OS.

I use kubeadm to deploy kubernetes. kubeadm can be used in these OS
* Ubuntu 16.04+
*  Debian 9+
*  CentOS 7
*  Red Hat Enterprise Linux (RHEL) 7
*  Fedora 25+
*  HypriotOS v1.0.1+
*  Container Linux (tested with 1800.6.0)

## Prerequisites:

* Install [Virtualbox](https://www.virtualbox.org/wiki/Linux_Downloads)
* Install [Vagrant](https://www.vagrantup.com/docs/installation/)
* Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Schema of the cluster.
The kubernetes cluster is simple and is only composed of 3 nodes.
* the master node call `kmaster` with ip : `172.42.42.100`
* a worker node call `kworker1` with ip : `172.42.42.101`
* a worker node call `kworker2` with ip : `172.42.42.102`
 
## Deploying the claster

Go to the `vagrant/` directory and execute vagrant.
```shell script
vagrant up
```
This will take some minutes, but at the end the cluster should be deployed and working.

## Testing the cluster
We can test the cluster with the master node. But it will be easier to test from the host machine.
To to that we will install kubectl on the host and configure it to access the cluster. 

Kubectl is the main tool to manipulate a kubernetes cluster using command line.

1. Install the [kubectl tool](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/#pr%c3%a9-requis)
2. In order to not use IP address, we will modifie the file `/etc/hosts`. Add this in this files: 
```shell script
172.42.42.100 kmaster.example.com kmaster
172.42.42.101 kworker1.example.com kworker1
172.42.42.102 kworker2.example.com kworker2

```
3. Create a `.kube` directory on you user home
```shell script
mkdir -p $HOME/.kube
``` 
(if this directory exist, remove everything existing inside)
4. Copy from the master node the file `$HOME/.kube/config`
```shell script
vagrant scp kmaster:.kube/config ~/.kube/
```
Now we should be able to tests our deployment. 

````shell script
kubectl cluster-info
````
it should show you this : 
```shell script
Kubernetes master is running at https://172.42.42.100:6443
KubeDNS is running at https://172.42.42.100:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```
Then lets check if all the main components are ready : 
```shell script
 kubectl get componentstatuses 
```
The result should be : 
```shell script
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
scheduler            Healthy   ok    
```
Then lets check if all nodes are ready : 
````shell script
kubectl get node
````
The result should be : 
````shell script
NAME                   STATUS   ROLES    AGE   VERSION
kmaster.example.com    Ready    master   17m   v1.17.3
kworker1.example.com   Ready    <none>   14m   v1.17.3
kworker2.example.com   Ready    <none>   10m   v1.17.3
````
Now lets try to install a nginx server: 
```shell script
kubectl run nginx --image nginx
```
This should create thes kubernetes objects : 
* 1 Deployment 
= 1 Pod
* 1 ReplicaSet

To check this: 
```shell script
kubectl get all
```
It should give this result: 
```shell script
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-6db489d4b7-s9t7s   1/1     Running   0          48s


NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   21m


NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           48s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-6db489d4b7   1         1         1       48s
```
Let's add a service to be able to access it.
```shell script
kubectl expose deployment nginx --type=NodePort --port 80 
```
This create a service of type NodePort which provide access to nging using a port.
To know this port : 
```shell script
kubect get svc
```
```shell script
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        29m
nginx        NodePort    10.110.193.72   <none>        80:31932/TCP   3s
```
In my case, the port is : `31932`. A NodePort give access to a service from all workers node.
So to access to the nginx server, you can use `http://kworker1:31932/` or `http://kworker2:31932/`.

