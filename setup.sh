#!/bin/bash
set -x
# Step 2 — Creating a Non-Root User on All Remote Servers
ansible-playbook -i hosts ~/kube-cluster/initial.yml
# Step 3 — Installing Kubernetetes’ Dependencies
ansible-playbook -i hosts ~/kube-cluster/kube-dependencies.yml
# Step 4 — Setting Up the Control Plane Node
ansible-playbook -i hosts ~/kube-cluster/control-plane.yml
# Test Control Plane Node
kubectl get nodes
# Output
# NAME     STATUS   ROLES                  AGE   VERSION
# control1   Ready    control-plane,master   51s   v1.22.4
# Step 5 — Setting Up the Worker Nodes
ansible-playbook -i hosts ~/kube-cluster/workers.yml
# Step 6 — Verifying the Cluster
kubectl get nodes
# Output
# NAME     STATUS   ROLES                  AGE     VERSION
# control1   Ready    control-plane,master   3m21s   v1.22.0
# worker1  Ready    <none>                 32s     v1.22.0
# worker2  Ready    <none>                 32s     v1.22.0
# Step 7 — Running An Application on the Cluster
kubectl create deployment nginx --image=nginx
kubectl expose deploy nginx --port 80 --target-port 80 --type NodePort
kubectl get services
# Output
# NAME         TYPE        CLUSTER-IP       EXTERNAL-IP           PORT(S)             AGE
# kubernetes   ClusterIP   10.96.0.1        <none>                443/TCP             1d
# nginx        NodePort    10.109.228.209   <none>                80:nginx_port/TCP   40m

# To test that everything is working, visit http://worker_1_ip:nginx_port or http://worker_2_ip:nginx_port through a browser on your local machine. You will see Nginx’s familiar welcome page.

# If you would like to remove the Nginx application, first delete the nginx service from the control plane node:

# kubectl delete service nginx
# Copy
# Run the following to ensure that the service has been deleted:

# kubectl get services
# Copy
# You will see the following output:

# Output
# NAME         TYPE        CLUSTER-IP       EXTERNAL-IP           PORT(S)        AGE
# kubernetes   ClusterIP   10.96.0.1        <none>                443/TCP        1d
# Then delete the deployment:

# kubectl delete deployment nginx
# Copy
# Run the following to confirm that this worked:

# kubectl get deployments
# Copy
# Output
# No resources found.