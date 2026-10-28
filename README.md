# Google Cloud Engineering Certificate (GCEC) - Hands-on Labs & Solutions

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE-326CE5?logo=kubernetes&logoColor=white)](https://cloud.google.com/kubernetes-engine)
[![Cloud Build](https://img.shields.io/badge/CI%2FCD-Cloud%20Build-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/build)
[![Artifact Registry](https://img.shields.io/badge/Registry-Artifact%20Registry-34A853?logo=google&logoColor=white)](https://cloud.google.com/artifact-registry)
[![Networking](https://img.shields.io/badge/VPC-Networking-34A853?logo=google&logoColor=white)](https://cloud.google.com/vpc)
[![Compute Engine](https://img.shields.io/badge/Compute%20Engine-VMs-FBBC05?logo=google-cloud&logoColor=white)](https://cloud.google.com/compute)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A curated collection of automated solutions, scripts, architectural blueprints, and walkthroughs for the **Google Cloud Engineering Certificate** pathway on **Google Cloud Skills Boost / Qwiklabs**.

---

## 📚 Labs in this Repository

| Lab Name / ID | Lab Title | Course / Badge | Solution & Guide |
| :--- | :--- | :--- | :---: |
| **GSP321** | **Develop your Google Cloud Network: Challenge Lab** | Develop Your Google Cloud Network | [View Solution](#-gsp321-develop-your-google-cloud-network-challenge-lab) |
| **CBL011** | **Deploy a LAMP Stack with Google Cloud Marketplace** | Essential Google Cloud Infrastructure: Foundation | [View Solution](./CBL011-deploy-lamp-stack-marketplace) |
| **CBL057** | **Create and Configure VPC Networks** | Essential Google Cloud Infrastructure: Foundation | [View Solution](./CBL057-create-and-configure-vpc-networks) |
| **CBL188** | **Implement Private Google Access and Cloud NAT** | Essential Google Cloud Infrastructure: Foundation | [View Solution](./CBL188-implement-private-google-access-and-cloud-nat) |
| **CBL138** | **Accessing the Google Cloud Console and Cloud Shell** | Getting Started with Google Kubernetes Engine | [View Solution](./CBL138-accessing-cloud-console-and-cloud-shell) |
| **GKE-Autopilot** | **Deploying GKE Autopilot Clusters from Cloud Shell** | Getting Started with Google Kubernetes Engine | [View Solution](./GKE-autopilot-clusters-from-cloud-shell) |
| **GKE-Console** | **Deploying GKE Autopilot Clusters** | Getting Started with Google Kubernetes Engine | [View Solution](./GKE-deploying-autopilot-clusters) |
| **CBL139** | **Working with Cloud Build** | Getting Started with Google Kubernetes Engine | [View Solution](./CBL139-working-with-cloud-build) |
| **GSP015** | **Running a Containerized App on Google Kubernetes Engine** | Getting Started with Google Kubernetes Engine | [View Solution](./GSP015-running-a-containerized-app-on-gke) |
| **CBL037** | **Configure Cloud SQL** | Essential Google Cloud Infrastructure: Core Services | [View Solution](./CBL037-configure-cloud-sql) |
| **CBL009** | **Examine Billing data with BigQuery** | Essential Google Cloud Infrastructure: Core Services | [View Solution](./CBL009-examine-billing-data-with-bigquery) |

---

## 🌟 CBL009: Examine Billing data with BigQuery

* **Directory:** [`./CBL009-examine-billing-data-with-bigquery`](./CBL009-examine-billing-data-with-bigquery)
* **Goal:** Create BigQuery dataset `billing_dataset`, import Avro billing data from Cloud Storage into `sampleinfotable`, and run analytical queries.
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/CBL009-examine-billing-data-with-bigquery
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```
* **In-Lab Quiz Answers:**
  * Total rows in table: **`9,738`**
  * Rows with cost > 0: **`104 rows`**
  * Product with most billing records: **`Compute Engine has 281136 records`**
  * Product with most records > $1: **`Cloud Storage has 17 charges costing more than 62 dollar.`**
  * Most commonly charged unit: **`Requests were the most commonly charged unit of measure.`**
  * Product with highest total cost: **`Compute Engine has an aggregate cost of $2548.77`**

---

## 🌟 CBL037: Configure Cloud SQL

* **Directory:** [`./CBL037-configure-cloud-sql`](./CBL037-configure-cloud-sql)
* **Goal:** Configure Cloud SQL (MySQL 8.0 Enterprise) with Private Services Access (PSA) and Public IP, setup Cloud SQL Auth Proxy on `wordpress-proxy`, and configure direct Private IP connection on `wordpress-private-ip`.
* **1-Command Quickstart (prompts user for Region and Zone):**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/CBL037-configure-cloud-sql
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```
* **Direct Parameter Passing:**
  ```bash
  ./solve.sh <REGION> <ZONE> [PASSWORD]
  ```

---

## 🌟 GSP015: Running a Containerized App on Google Kubernetes Engine

* **Directory:** [`./GSP015-running-a-containerized-app-on-gke`](./GSP015-running-a-containerized-app-on-gke)
* **Goal:** Create a 3-node GKE cluster (`hello-world`) in `us-central1-f`, build and publish a Golang container image to Container Registry, deploy the app, and expose it publicly via a LoadBalancer service.
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/GSP015-running-a-containerized-app-on-gke
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```
* **In-Lab Quiz Answers:**
  1. *docker push publish the container image in Google Cloud to ____.* ➡️ **`Artifact Registry`**
  2. *Kubernetes is an open-source container-orchestration system for automating deployment, scaling and management of containerized applications.* ➡️ **`True`**
  3. *In Kubernetes environment, kubectl expose creates a ____, the forwarding rules for the load balancer, and the firewall rules that allow external traffic to be sent to the pod.* ➡️ **`Service`**

---

## 🌟 CBL139: Working with Cloud Build

* **Directory:** [`./CBL139-working-with-cloud-build`](./CBL139-working-with-cloud-build)
* **Goal:** Build Docker container images with Dockerfiles and Cloud Build, store artifacts in Artifact Registry (`us-east4`), write custom build configuration files (`cloudbuild.yaml`), and implement automated container testing and failure handling (`cloudbuild2.yaml`).
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/CBL139-working-with-cloud-build
  chmod +x solve.sh verify.sh quickstart.sh
  ./solve.sh
  ```

---

## 🌟 GKE: Deploying GKE Autopilot Clusters

* **Directory:** [`./GKE-deploying-autopilot-clusters`](./GKE-deploying-autopilot-clusters)
* **Goal:** Deploy a regional GKE Autopilot cluster (`autopilot-cluster-1`) in `us-west1` and deploy a 3-replica `nginx-1` sample workload.
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/GKE-deploying-autopilot-clusters
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```

---

## 🌟 GKE: Deploying GKE Autopilot Clusters from Cloud Shell

* **Directory:** [`./GKE-autopilot-clusters-from-cloud-shell`](./GKE-autopilot-clusters-from-cloud-shell)
* **Goal:** Create a GKE Autopilot cluster (`autopilot-cluster-1`), connect using `kubectl`, deploy containerized workloads (`nginx-1`), inject static content, expose via LoadBalancer, and deploy pods declaratively via YAML manifests (`new-nginx`).
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/GKE-autopilot-clusters-from-cloud-shell
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```

---

## 🌟 CBL138: Accessing the Google Cloud Console and Cloud Shell

* **Directory:** [`./CBL138-accessing-cloud-console-and-cloud-shell`](./CBL138-accessing-cloud-console-and-cloud-shell)
* **Goal:** Navigate Cloud Console and Cloud Shell, deploy a Compute Engine VM with HTTP firewall rules, create an IAM service account with Editor privileges, manage Cloud Storage buckets and public objects, and serve a custom Nginx website.
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/CBL138-accessing-cloud-console-and-cloud-shell
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```

---

## 🌟 CBL188: Implement Private Google Access and Cloud NAT

* **Directory:** [`./CBL188-implement-private-google-access-and-cloud-nat`](./CBL188-implement-private-google-access-and-cloud-nat)
* **Goal:** Configure a private Compute Engine VM without an external IP, connect securely via Cloud IAP tunneling, enable Private Google Access for Google APIs (Cloud Storage), and deploy Cloud NAT for outbound internet package updates.
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/CBL188-implement-private-google-access-and-cloud-nat
  chmod +x solve.sh verify.sh
  ./solve.sh
  ```

---

## 🌟 CBL057: Create and Configure VPC Networks

* **Directory:** [`./CBL057-create-and-configure-vpc-networks`](./CBL057-create-and-configure-vpc-networks)
* **Goal:** Explore default networks, create auto mode VPCs, convert auto to custom mode, deploy multi-VPC networks (`managementnet`, `privatenet`), and verify cross-network routing and firewall isolation.
* **1-Command Quickstart:**
  ```bash
  git clone https://github.com/KD0-7/lab-gcec.git
  cd lab-gcec/CBL057-create-and-configure-vpc-networks
  chmod +x solve.sh test_connectivity.sh
  ./solve.sh
  ```

---

## 🌟 CBL011: Deploy a LAMP Stack with Google Cloud Marketplace

* **Directory:** [`./CBL011-deploy-lamp-stack-marketplace`](./CBL011-deploy-lamp-stack-marketplace)
* **Goal:** Launch a click-to-deploy LAMP Stack (Linux, Apache, MySQL, PHP) via Google Cloud Marketplace on Compute Engine.
* **Key Configurations:**
  * **Solution:** LAMP Stack, by Google Click to Deploy
  * **Zone:** `europe-west1-c` *(or assigned lab zone)*
  * **Machine Type:** `e2-medium` (Series E2)
  * **Quiz Answer:** `Deployment Manager`
* **Verification:** Run `./verify.sh` in Cloud Shell or visit `http://<EXTERNAL_IP>`.

---

## 🌟 GSP321: Develop your Google Cloud Network: Challenge Lab

### 🚀 Quick Start (1-Command Cloud Shell Execution)

To complete all 9 tasks of GSP321 automatically in **under 5 minutes**:

```bash
git clone https://github.com/KD0-7/lab-gcec.git
cd lab-gcec
chmod +x solve.sh scripts/*.sh
./solve.sh
```

---

## 📁 Repository Structure

```
lab-gcec/
├── README.md                                           # Master repository documentation
├── solve.sh                                            # GSP321: All-in-one automated solution script
├── .gitattributes                                      # Enforces LF line endings for Linux/Cloud Shell
├── .gitignore                                          # Git ignore for keys and temporary credentials
├── CBL009-examine-billing-data-with-bigquery/         # Lab CBL009: Examine Billing data with BigQuery
│   ├── README.md                                       # Complete guide, query library & quiz answers
│   ├── solve.sh                                        # Automated provisioning & analysis script
│   ├── verify.sh                                       # Health check & table validation script
│   └── queries.sql                                     # All 7 analytical BigQuery SQL queries
├── CBL037-configure-cloud-sql/                         # Lab CBL037: Configure Cloud SQL
│   ├── README.md                                       # Complete guide, diagrams & dual-connection setup
│   ├── solve.sh                                        # Automated provisioning script (prompts region/zone)
│   └── verify.sh                                       # Health check & status validation script
├── GSP015-running-a-containerized-app-on-gke/         # Lab GSP015: Running a Containerized App on GKE
│   ├── README.md                                       # Complete guide & command breakdown
│   ├── solve.sh                                        # Automated provisioning script
│   └── verify.sh                                       # Health check & validation script
├── CBL139-working-with-cloud-build/                   # Lab CBL139: Working with Cloud Build
│   ├── README.md                                       # Complete guide & command breakdown
│   ├── solve.sh                                        # Automated provisioning script
│   ├── verify.sh                                       # Health check & validation script
│   ├── quickstart.sh                                   # Sample application script
│   ├── Dockerfile                                      # Container definition
│   ├── cloudbuild.yaml                                 # Custom build configuration
│   └── cloudbuild2.yaml                                # Test failure simulation
├── GKE-deploying-autopilot-clusters/                  # GKE Autopilot Clusters (Console/Workloads)
│   ├── README.md                                       # Complete guide & command breakdown
│   ├── solve.sh                                        # Automated provisioning script
│   └── verify.sh                                       # Health check & validation script
├── GKE-autopilot-clusters-from-cloud-shell/            # GKE Autopilot Clusters from Cloud Shell
│   ├── README.md                                       # Complete guide & command breakdown
│   ├── solve.sh                                        # Automated provisioning script
│   ├── fix_task4.sh                                    # Quick fix for pod exposure
│   └── verify.sh                                       # Health check & validation script
├── CBL138-accessing-cloud-console-and-cloud-shell/     # Lab CBL138: Cloud Console and Cloud Shell
│   ├── README.md                                       # Complete guide & command breakdown
│   ├── solve.sh                                        # Automated provisioning script
│   └── verify.sh                                       # Health check & validation script
├── CBL188-implement-private-google-access-and-cloud-nat/ # Lab CBL188: Private Google Access and Cloud NAT
│   ├── README.md                                       # Complete guide, diagrams & quiz answers
│   ├── solve.sh                                        # Automated provisioning script
│   └── verify.sh                                       # Health check & validation script
├── CBL057-create-and-configure-vpc-networks/           # Lab CBL057: Create and Configure VPC Networks
│   ├── README.md                                       # Complete guide & quiz answers
│   ├── solve.sh                                        # Automated provisioning script
│   └── test_connectivity.sh                            # Verification & ping test script
├── CBL011-deploy-lamp-stack-marketplace/               # Lab CBL011: Deploy a LAMP Stack with Marketplace
│   ├── README.md                                       # Step-by-step console guide & quiz answer
│   └── verify.sh                                       # Health check & Apache verification script
└── scripts/                                            # GSP321 modular task scripts
    ├── 01_dev_vpc.sh
    ├── 02_prod_vpc.sh
    ├── 03_bastion.sh
    ├── 04_cloud_sql.sh
    ├── 05_gke_cluster.sh
    ├── 06_wp_secrets.sh
    ├── 07_wp_deployment.sh
    ├── 08_monitoring.sh
    └── 09_iam_access.sh
```
