# Deploy a LAMP Stack with Google Cloud Marketplace (CBL011)

[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Marketplace](https://img.shields.io/badge/Cloud-Marketplace-34A853?logo=google&logoColor=white)](https://cloud.google.com/marketplace)
[![Apache](https://img.shields.io/badge/Server-Apache%20HTTP-D22128?logo=apache&logoColor=white)](https://httpd.apache.org/)
[![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![PHP](https://img.shields.io/badge/Framework-PHP-777BB4?logo=php&logoColor=white)](https://www.php.net/)

Comprehensive walkthrough and verification script for the Google Cloud lab: **Deploy a LAMP Stack with Google Cloud Marketplace (CBL011)**, part of the **Essential Google Cloud Infrastructure: Foundation** course in the **Google Cloud Engineering Certificate** pathway.

---

## 📌 Lab Overview

* **Course:** Essential Google Cloud Infrastructure: Foundation
* **Badge / Pathway:** Google Cloud Engineering Certificate
* **Lab ID:** `CBL011`
* **Target Environment:** Google Cloud Console & Marketplace
* **Duration:** 15 minutes

### LAMP Stack Architecture

| Component | Role | Description |
| :--- | :--- | :--- |
| **Linux** | Operating System | Base Debian Linux OS running on Compute Engine |
| **Apache HTTP Server** | Web Server | Serves static & dynamic web pages over port 80 |
| **MySQL** | Relational Database | Backend database engine for web applications |
| **PHP** | Web Framework | Server-side scripting language |
| **phpMyAdmin** | Administration Tool | Web-based interface to manage MySQL databases |

---

## ⚡ Step-by-Step Execution Guide

### Task 1: Deploy a LAMP Stack Using Cloud Marketplace

1. In the **Google Cloud Console**, open the **Navigation Menu (☰)** in the top-left corner and click **Marketplace**.
2. In the Marketplace search bar, type `LAMP` and press **Enter**.
3. In the search results, click **LAMP Stack, by Google Click to Deploy**.
   > **Note:** Choose the *Google Click to Deploy* option (do not select Bitnami or other variants as automated scoring checks for the Google template).
4. On the LAMP Stack product page, click **Get Started** (or **Deploy**).
5. On the Agreements page, check the box for **Terms and agreements**, then click **Agree**.
6. On the *Successfully agreed to terms* pop-up, click **Deploy**.
7. If prompted to enable the **Compute Engine API** and **Infrastructure Manager API**, click **Enable**.
8. Configure the deployment parameters:
   * **Zone:** `europe-west1-b` *(Crucial: must match the lab assigned zone)*
   * **Series:** `E2`
   * **Machine Type:** `e2-medium` (2 vCPU, 4 GB memory)
   * Leave all other settings as their default values.
9. Click **Deploy** at the bottom of the page.
10. Wait 1–2 minutes while Google Cloud Deployment Manager provisions the Compute Engine instance `lamp-1-vm` and configures firewall rules. The status will update to **`lamp-1 has been deployed`**.

#### 📝 In-Lab Assessment Question:
> **Question:** Which tool is used to deploy Google Cloud Marketplace solutions like the LAMP Stack?  
> **Answer:** **`Deployment Manager`**

11. Click **Check my progress** on the lab instructions panel for **Use Cloud Marketplace to deploy a LAMP stack** to receive your points!

---

### Task 2: Verify Your Deployment

1. On the deployment details page in the Google Cloud Console, locate your instance details.
2. Click **lamp-1-vm > Details** (or find the **Site address** / **Site Url** link).
3. Click the **Site Url** link (e.g., `http://<EXTERNAL_IP>`).
   * *If the website is not responding immediately, wait 30 seconds for Apache to finish its initial start.*
4. A new browser tab opens displaying the default welcome / congratulations page.
5. This confirms that the **Apache HTTP Server** is running and accessible over HTTP port 80.

---

## 💻 Cloud Shell Helper / Verification Script

If you want to verify the deployment status and test Apache connectivity directly from **Google Cloud Shell**:

```bash
git clone https://github.com/KD0-7/lab-gcec.git
cd lab-gcec/CBL011-deploy-lamp-stack-marketplace
chmod +x verify.sh
./verify.sh
```

---

## ✅ Score Checklist

| Task | Objective | Verification Item | Status |
| :--- | :--- | :--- | :---: |
| **Task 1** | Deploy LAMP stack | `lamp-1` deployed in `europe-west1-b` on `e2-medium` | Green ✔ |
| **Task 1 Quiz** | Assessment | Select **Deployment Manager** | Green ✔ |
| **Task 2** | Verify deployment | Open **Site Url** (`http://<IP>`) and confirm Apache running | Green ✔ |
