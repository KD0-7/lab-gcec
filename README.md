# Google Cloud Engineering Certificate (GCEC) - Hands-on Labs & Solutions

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
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
  * **Zone:** `europe-west1-b`
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
