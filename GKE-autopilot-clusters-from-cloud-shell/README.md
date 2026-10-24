# Deploying GKE Autopilot Clusters from Cloud Shell

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE%20Autopilot-326CE5?logo=kubernetes&logoColor=white)](https://cloud.google.com/kubernetes-engine)
[![Nginx](https://img.shields.io/badge/Web%20Server-Nginx-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Comprehensive automated solution, scripts, and documentation for the Google Cloud Skills Boost lab: **Deploying GKE Autopilot Clusters from Cloud Shell**, part of the **Getting Started with Google Kubernetes Engine** course in the **Google Cloud Engineering Certificate** pathway.

---

## 🚀 Quick Start (1-Command Cloud Shell Execution)

To complete all 5 tasks and 3 checkpoints automatically in Cloud Shell:

```bash
git clone https://github.com/KD0-7/lab-gcec.git
cd lab-gcec/GKE-autopilot-clusters-from-cloud-shell
chmod +x solve.sh verify.sh
./solve.sh
```

---

## 🏛️ GKE Autopilot Architecture

```mermaid
graph TD
    subgraph "GKE Autopilot Cluster: autopilot-cluster-1 (us-west1)"
        subgraph "Google-Managed Control Plane & Node Pools"
            AUTOPILOT["GKE Autopilot Engine<br/>Auto-provisions nodes & scales based on Pod specs"]
        end

        subgraph "Workloads (default namespace)"
            DEPLOY["Deployment: nginx-1"]
            POD1["Pod: nginx-1-xxxx<br/>Image: nginx<br/>Static file: /usr/share/nginx/html/test.html"]
            POD2["Pod: new-nginx<br/>Image: nginx<br/>Applied via YAML manifest"]
            DEPLOY --> POD1
        end

        subgraph "Services & Networking"
            LB["Service: LoadBalancer<br/>Exposes Pod on External IP:80"]
        end
    end

    LB --> POD1
    CLIENT["Browser Client / curl"] -->|HTTP :80/test.html| LB
```

---

## 📋 Task Breakdown & Solutions

### Task 1: Deploy GKE Autopilot Cluster
* **Cluster Name:** `autopilot-cluster-1`
* **Region:** `us-west1`
* **Cluster Type:** Autopilot (`create-auto`)

```bash
export my_region=us-west1
export my_cluster=autopilot-cluster-1

gcloud container clusters create-auto $my_cluster --region $my_region
```

---

### Task 2 & 3: Connect and Inspect Kubeconfig
* Generate kubeconfig credentials:
```bash
gcloud container clusters get-credentials $my_cluster --region $my_region
```
* Inspect cluster information and contexts:
```bash
kubectl cluster-info
kubectl config current-context
kubectl config get-contexts
```

---

### Task 4: Deploy Pods, Inject Static Files & Expose LoadBalancer
* Deploy Nginx:
```bash
kubectl create deployment --image=nginx nginx-1
```
* Wait for Pod to become ready, then copy `test.html` into container:
```bash
my_nginx_pod=$(kubectl get pods -l app=nginx-1 -o jsonpath='{.items[0].metadata.name}')

cat <<EOF > ~/test.html
<header><title>This is title</title></header> Hello world
EOF

kubectl cp ~/test.html $my_nginx_pod:/usr/share/nginx/html/test.html
```
* Expose the Pod with a public LoadBalancer service:
```bash
kubectl expose pod $my_nginx_pod --port=80 --type=LoadBalancer
```

---

### Task 5: Introspect GKE Pods & Deploy via YAML Manifest
* Deploy `new-nginx` Pod using a declarative manifest:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: new-nginx
  labels:
    name: new-nginx
spec:
  containers:
  - name: new-nginx
    image: nginx
    ports:
    - containerPort: 80
EOF
```
* Verify running status:
```bash
kubectl get pods
```

---

## 🔍 Verification

Run `verify.sh` to confirm cluster and workload status:

```bash
./verify.sh
```

---

## ✅ Score Checklist

| Checkpoint | Target Resource | Status |
| :--- | :--- | :---: |
| **Check 1** | GKE Autopilot cluster `autopilot-cluster-1` in `us-west1` | Green ✔ |
| **Check 2** | `nginx-1` Pod running + `test.html` copied + LoadBalancer service | Green ✔ |
| **Check 3** | `new-nginx` Pod deployed via YAML manifest | Green ✔ |
