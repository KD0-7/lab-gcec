# Create and Configure VPC Networks (CBL057)

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Networking](https://img.shields.io/badge/VPC-Networking-34A853?logo=google&logoColor=white)](https://cloud.google.com/vpc)
[![Compute Engine](https://img.shields.io/badge/Compute%20Engine-VMs-FBBC05?logo=google-cloud&logoColor=white)](https://cloud.google.com/compute)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Comprehensive automated solution, scripts, and documentation for the Google Cloud Skills Boost lab: **Create and Configure VPC Networks (CBL057)**, part of the **Essential Google Cloud Infrastructure: Foundation** course in the **Google Cloud Engineering Certificate** pathway.

---

## 🚀 Quick Start (1-Command Cloud Shell Execution)

To complete all tasks automatically in **under 3 minutes**:

1. Open **Google Cloud Shell** in your active lab session.
2. Clone this repository and execute `solve.sh`:

```bash
git clone https://github.com/KD0-7/lab-gcec.git
cd lab-gcec/CBL057-create-and-configure-vpc-networks
chmod +x solve.sh test_connectivity.sh
./solve.sh
```

---

## 🏛️ Network Topology & Architecture

```mermaid
graph TD
    subgraph "mynetwork (converted from auto to custom)"
        subgraph "us-east1 (10.142.0.0/20)"
            VM1["mynet-us-vm<br/>e2-medium (us-east1-c)<br/>Tag: iap-gce"]
        end
        subgraph "asia-southeast1 (10.148.0.0/20)"
            VM2["mynet-notus-vm<br/>e2-medium (asia-southeast1-c)<br/>Tag: iap-gce"]
        end
    end

    subgraph "managementnet (custom mode)"
        subgraph "managementsubnet-us (10.240.0.0/20)"
            VM3["managementnet-us-vm<br/>e2-micro (us-east1-c)"]
        end
    end

    subgraph "privatenet (custom mode)"
        subgraph "privatesubnet-us (172.16.0.0/24)"
            VM4["privatenet-us-vm<br/>e2-micro (us-east1-c)"]
        end
        subgraph "privatesubnet-notus (172.20.0.0/20)"
            REMOTE_SUBNET["[Ready for Asia workloads]"]
        end
    end

    VM1 <-->|Internal Ping: SUCCESS (Same VPC)| VM2
    VM1 -.->|Internal Ping: BLOCKED (Isolated VPC)| VM3
    VM1 -.->|Internal Ping: BLOCKED (Isolated VPC)| VM4
```

---

## 📝 In-Lab Quiz Questions & Answers

| # | Question | Correct Answer |
| :-: | :--- | :--- |
| **1** | Without a VPC network, you cannot create VM instances, containers, or App Engine applications. | **`True`** |
| **2** | Which firewall rule allows the ping to `mynet-notus-vm`'s external IP address? | **`mynetwork-allow-icmp`** |
| **3** | Which instances should you be able to ping from `mynet-us-vm` using internal IP addresses? | **`mynet-notus-vm`** |

---

## 📋 Task Breakdown & Solutions

### Task 1: Explore the Default Network
* Inspect the pre-existing default VPC, subnets, routes, and firewall rules.
* Delete default firewall rules and default network to demonstrate that VMs cannot be launched without a VPC network.

```bash
# Delete all default firewall rules
gcloud compute firewall-rules list --filter="network:default" --format="value(name)" | xargs -r -n 1 gcloud compute firewall-rules delete --quiet

# Delete default network
gcloud compute networks delete default --quiet
```

---

### Task 2: Create Auto Mode Network & VM Instances
* Enable APIs: `iap.googleapis.com` and `networkmanagement.googleapis.com`
* Create auto mode VPC `mynetwork`
* Configure standard firewall rules (`allow-icmp`, `allow-ssh`, `allow-rdp`, `allow-custom`, `allow-iap-ssh`)
* Deploy 2 VMs:
  * `mynet-us-vm` in `us-east1-c` (`e2-medium`)
  * `mynet-notus-vm` in `asia-southeast1-c` (`e2-medium`)
* Convert `mynetwork` to custom mode:

```bash
gcloud compute networks create mynetwork --subnet-mode=auto

gcloud compute firewall-rules create mynetwork-allow-icmp --network=mynetwork --priority=65534 --rules=icmp --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create mynetwork-allow-ssh --network=mynetwork --priority=65534 --rules=tcp:22 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create mynetwork-allow-rdp --network=mynetwork --priority=65534 --rules=tcp:3389 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create mynetwork-allow-custom --network=mynetwork --priority=65534 --rules=all --source-ranges=10.128.0.0/9
gcloud compute firewall-rules create allow-iap-ssh --network=mynetwork --priority=1000 --rules=tcp:22 --source-ranges=35.235.240.0/20 --target-tags=iap-gce

gcloud compute instances create mynet-us-vm --zone=us-east1-c --machine-type=e2-medium --subnet=mynetwork --tags=iap-gce --image-family=debian-12 --image-project=debian-cloud --boot-disk-size=10GB
gcloud compute instances create mynet-notus-vm --zone=asia-southeast1-c --machine-type=e2-medium --subnet=mynetwork --tags=iap-gce --image-family=debian-12 --image-project=debian-cloud --boot-disk-size=10GB

# Convert to custom mode
gcloud compute networks update mynetwork --switch-to-custom-subnet-mode --quiet
```

---

### Task 3: Create Custom Mode Networks with Firewall Rules
* Create `managementnet` custom VPC with subnet `managementsubnet-us` (`10.240.0.0/20` in `us-east1`)
* Create `privatenet` custom VPC with subnets:
  * `privatesubnet-us` (`172.16.0.0/24` in `us-east1`)
  * `privatesubnet-notus` (`172.20.0.0/20` in `asia-southeast1`)
* Create firewall rules:
  * `managementnet-allow-icmp-ssh-rdp` (`icmp,tcp:22,tcp:3389`)
  * `privatenet-allow-icmp-ssh-rdp` (`icmp,tcp:22,tcp:3389`)
* Deploy VMs:
  * `managementnet-us-vm` in `us-east1-c` (`e2-micro`) on `managementsubnet-us`
  * `privatenet-us-vm` in `us-east1-c` (`e2-micro`) on `privatesubnet-us`

```bash
# managementnet
gcloud compute networks create managementnet --subnet-mode=custom
gcloud compute networks subnets create managementsubnet-us --network=managementnet --region=us-east1 --range=10.240.0.0/20
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp --network=managementnet --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0
gcloud compute instances create managementnet-us-vm --zone=us-east1-c --machine-type=e2-micro --subnet=managementsubnet-us --image-family=debian-12 --image-project=debian-cloud --boot-disk-size=10GB

# privatenet
gcloud compute networks create privatenet --subnet-mode=custom
gcloud compute networks subnets create privatesubnet-us --network=privatenet --region=us-east1 --range=172.16.0.0/24
gcloud compute networks subnets create privatesubnet-notus --network=privatenet --region=asia-southeast1 --range=172.20.0.0/20
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --network=privatenet --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0
gcloud compute instances create privatenet-us-vm --zone=us-east1-c --machine-type=e2-micro --subnet=privatesubnet-us --image-family=debian-12 --image-project=debian-cloud --boot-disk-size=10GB
```

---

### Task 4: Explore Connectivity Across Networks
* **External Ping:** Pinging public IPs succeeds for all instances due to ICMP firewall rules (`0.0.0.0/0`).
* **Internal Ping:**
  * `mynet-us-vm` ➡️ `mynet-notus-vm`: **Success** (both belong to `mynetwork`).
  * `mynet-us-vm` ➡️ `managementnet-us-vm`: **100% Packet Loss** (different VPC).
  * `mynet-us-vm` ➡️ `privatenet-us-vm`: **100% Packet Loss** (different VPC).

To test connectivity directly:
```bash
./test_connectivity.sh
```

---

## ✅ Score Checklist

| Checkpoint | Target Resources | Status |
| :--- | :--- | :---: |
| **Check 1** | `mynetwork` in custom mode + `mynet-us-vm` + `mynet-notus-vm` | Green ✔ |
| **Check 2** | `managementnet` & `privatenet` VPCs + subnets + firewall rules | Green ✔ |
| **Check 3** | `managementnet-us-vm` & `privatenet-us-vm` instances running | Green ✔ |
