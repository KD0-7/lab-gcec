# Google Cloud Engineering Certificate (GCEC) - Hands-on Labs & Solutions

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Networking](https://img.shields.io/badge/VPC-Networking-34A853?logo=google&logoColor=white)](https://cloud.google.com/vpc)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A curated collection of automated solutions, scripts, architectural blueprints, and walkthroughs for the **Google Cloud Engineering Certificate** pathway on **Google Cloud Skills Boost / Qwiklabs**.

---

## 📚 Labs in this Repository

| Lab ID | Lab Title | Course / Badge | Solution & Guide |
| :--- | :--- | :--- | :---: |
| **GSP321** | **Develop your Google Cloud Network: Challenge Lab** | Develop Your Google Cloud Network | [View Solution](#-gsp321-develop-your-google-cloud-network-challenge-lab) |
| **CBL011** | **Deploy a LAMP Stack with Google Cloud Marketplace** | Essential Google Cloud Infrastructure: Foundation | [View Solution](./CBL011-deploy-lamp-stack-marketplace) |
| **CBL057** | **Create and Configure VPC Networks** | Essential Google Cloud Infrastructure: Foundation | [View Solution](./CBL057-create-and-configure-vpc-networks) |

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
* **In-Lab Quiz Answers:**
  1. *Without a VPC network, you cannot create VM instances, containers, or App Engine applications.* ➡️ **True**
  2. *Which firewall rule allows the ping to mynet-notus-vm's external IP address?* ➡️ **`mynetwork-allow-icmp`**
  3. *Which instances should you be able to ping from mynet-us-vm using internal IP addresses?* ➡️ **`mynet-notus-vm`**

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

> **Tip:** You will be prompted for **Username 2** (Additional Engineer email for Task 9). You can also provide it directly:
> ```bash
> ./solve.sh "<USERNAME_2_EMAIL>"
> ```

### 🏛️ Network Architecture & Topology

```mermaid
graph TD
    subgraph "griffin-dev-vpc (192.168.0.0/16)"
        subgraph "griffin-dev-mgmt (192.168.32.0/20)"
            NIC0["Bastion Host: nic0"]
        end
        subgraph "griffin-dev-wp (192.168.16.0/20)"
            GKE["GKE Cluster: griffin-dev<br/>(2x e2-standard-4)"]
            WP["WordPress Pods + Cloud SQL Proxy"]
        end
    end

    subgraph "griffin-prod-vpc (192.168.0.0/16)"
        subgraph "griffin-prod-mgmt (192.168.64.0/20)"
            NIC1["Bastion Host: nic1"]
        end
        subgraph "griffin-prod-wp (192.168.48.0/20)"
            PROD_WP["Production Workloads"]
        end
    end

    subgraph "Managed Services"
        SQL["Cloud SQL MySQL: griffin-dev-db<br/>DB: wordpress | User: wp_user"]
        LB["External HTTP Load Balancer"]
        MON["Cloud Monitoring Uptime Check"]
    end

    NIC0 --- NIC1
    WP -->|Cloud SQL Proxy Sidecar| SQL
    LB --> WP
    MON -->|Probes :80| LB
```

---

## 📁 Repository Structure

```
lab-gcec/
├── README.md                                   # Master repository documentation
├── solve.sh                                    # GSP321: All-in-one automated solution script
├── .gitattributes                              # Enforces LF line endings for Linux/Cloud Shell
├── .gitignore                                  # Git ignore for keys and temporary credentials
├── CBL057-create-and-configure-vpc-networks/   # Lab CBL057: Create and Configure VPC Networks
│   ├── README.md                               # Complete guide & quiz answers
│   ├── solve.sh                                # Automated provisioning script
│   └── test_connectivity.sh                    # Verification & ping test script
├── CBL011-deploy-lamp-stack-marketplace/       # Lab CBL011: Deploy a LAMP Stack with Marketplace
│   ├── README.md                               # Step-by-step console guide & quiz answer
│   └── verify.sh                               # Health check & Apache verification script
└── scripts/                                    # GSP321 modular task scripts
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
