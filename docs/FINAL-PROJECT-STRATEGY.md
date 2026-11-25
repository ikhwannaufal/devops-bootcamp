# Final Project Strategy: How to Pass the Rubric

Companion to [`FINAL-PROJECT-PREP.md`](./FINAL-PROJECT-PREP.md). That file explains *what you learned*. This file explains *how to turn it into marks*.

Source: the instructor slides "Final Project — Trust Me, I'm a DevOps Engineer" (17 slides). Wording in the rubric tables is translated from Malay. Anything marked **(confirm)** is my interpretation or something the slides don't say, so ask your instructors.

---

## 1. The scoreboard

**Pass condition (slide 13):** minimum **60%**, **every section** scored, and the **app URL and Grafana dashboard live**.

| Section | Pts | Criterion | Pts |
|---|---|---|---|
| **Infrastructure Provisioning** | 30 | S3 backend | 5 |
| | | VPC network | 10 |
| | | Security groups | 5 |
| | | 3 × EC2 | 10 |
| **Configuration Management** | 25 | Ansible controller | 5 |
| | | Docker installed via Ansible | 5 |
| | | App as container | 5 |
| | | Image in ECR | 5 |
| | | Repeatable (idempotent) | 5 |
| **Monitoring & Observability** | 20 | Prometheus configured | 8 |
| | | Grafana dashboard | 8 |
| | | Web server metrics | 4 |
| **Domain & Secure Access** | 15 | Domain → app | 5 |
| | | Cloudflare Tunnel | 7 |
| | | Monitoring not public | 3 |
| **Documentation** | 10 | GitHub Pages on | 3 |
| | | URLs documented | 4 |
| | | Structured explanation | 3 |
| **Total** | **100** | | |
| **Bonus** | **+22** | see section 6 | |

**Important reading of the rules**
- "All sections" most likely means you cannot pass by skipping a section entirely **(confirm)**. A half-working version of every section beats a perfect version of three.
- **There is no presentation.** You are graded from artifacts: the public repo, the live URLs, the Grafana login and the Pages site. If a grader cannot *see* something, it does not exist. Plan evidence for every row (section 5).
- The cheapest points in the whole rubric are in **Documentation (10%)** and **Monitoring not public (3%)**. Do not leave them for the last five minutes.

---

## 2. Target scores

| Goal | What you need |
|---|---|
| **Safe pass (≥ 60)** | All of Infrastructure (30) + Configuration (25) + a working dashboard (8) = 63, then the docs |
| **Strong (≈ 85)** | Everything except part of Domain/Docs polish |
| **Full marks (100)** | The whole rubric |
| **Beyond (up to 122)** | Add bonuses only after the base is solid and documented |

**Rule of thumb:** 85% of your effort on the 100 base points. Bonuses are for leftover time.

---

## 3. What you can reuse from this repo

You already built about 70% of this. Reuse by copying the *pattern*, not the folder.

| Final-project need | Reuse from | What to change |
|---|---|---|
| S3 backend | `terraform2/providers.tf` | New bucket `devops-bootcamp-terraform-<nama>`, key `final-project/terraform.tfstate` |
| VPC + public/private + NAT | `terraform3/network.tf` | CIDR `10.0.0.0/24`, subnets `/25`, names from slide 4 |
| Security groups via module | `terraform3/security.tf` | Two SGs and the exact rules from slide 4 |
| EC2 via module + SSM profile | `terraform3/ec2.tf`, `terraform4/ec2.tf` | Three servers, fixed private IPs, an IAM role per server |
| Tunnel token from SSM | `terraform3/ec2.tf` (`data.aws_ssm_parameter.token`) | Same idea for the monitoring server |
| Cloudflare tunnel container | `terraform3/userdata-tunnel.sh` | Run it on the monitoring server |
| Docker role | `grafana/playbook-stack.yaml` (`geerlingguy.docker`) | Run on web, controller and monitoring |
| node_exporter | `grafana/playbook-exporter.yaml` | Only the web server needs it |
| Monitoring stack | `grafana/compose.yaml`, `grafana/prometheus.yaml`, `grafana/playbook-stack.yaml` | Target becomes `10.0.0.5:9100` |
| Templates / handlers | `ansible2/playbook-web.yaml` | Only if you template configs |
| Multi-stage Dockerfile | `docker2/Dockerfile` | Adapt to the `Infratify/ship` app |
| ECR login/push commands | `docker2/notes.txt` | New repo name |
| Pages workflow | `cicd4/cicd1.md` (steps + `permissions`) | Publish the README instead of a Node build |
| Dashboard | `grafana/dashboard.json` | Add a **memory** panel (see 4.3) |

---

## 4. Section-by-section strategy

### 4.1 Infrastructure Provisioning (30%)

**Order matters.** The state bucket must exist *before* `terraform init`, so create it by hand, then everything else with Terraform.

```bash
aws s3api create-bucket --bucket devops-bootcamp-terraform-<nama> \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1
aws s3api put-bucket-versioning --bucket devops-bootcamp-terraform-<nama> \
  --versioning-configuration Status=Enabled
```

| Criterion | How to earn all the points | Trap |
|---|---|---|
| **Backend (5)** | `backend "s3"` block with `use_lockfile = true`; `terraform init` shows "Successfully configured the backend" | A bucket name that doesn't match slide 4 |
| **VPC (10)** | One VPC `10.0.0.0/24`, public `10.0.0.0/25`, private `10.0.0.128/25`, **two** route tables, one IGW, one NAT. Use the exact names: `devops-vpc`, `devops-public-subnet`, `devops-private-subnet`, `devops-public-route`, `devops-private-route`, `devops-igw`, `devops-ngw` | The registry VPC module names things its own way. Set the `Name` tags with `public_subnet_names`, `private_subnet_names`, `public_route_table_tags`, `private_route_table_tags`, `igw_tags`, `nat_gateway_tags`, then **check the names in the AWS console** |
| **SGs (5)** | `devops-public-sg`: 80 from `0.0.0.0/0`, **9100 from `10.0.0.136/32`**, 22 from `10.0.0.0/24`. `devops-private-sg`: 22 from `10.0.0.0/24`. Egress open | Opening 9100 to the whole internet or the whole VPC loses the "least privilege" point |
| **EC2 (10)** | Web `10.0.0.5` (public subnet, Elastic IP), controller `10.0.0.135` and monitoring `10.0.0.136` (private subnet). SSM instance profile on all three | AWS reserves the first 4 and the last address of each subnet. `.5`, `.135` and `.136` are all fine, but `.1`–`.3` and `.129`–`.131` are not. |

Practical notes
- A fixed `private_ip` on each instance is what makes everything later simple. Prometheus, the inventory and the SG rule all use known addresses, so the "stale IP" problem from `FINAL-PROJECT-PREP.md` (gotcha #1) disappears.
- Create the Elastic IP with `aws_eip` and attach it to the web server.
- Keep one `terraform/` folder with the usual split (`providers.tf`, `network.tf`, `security.tf`, `ec2.tf`, `outputs.tf`), as in your lessons.
- The controller needs to **clone your repo and run Ansible** after boot, so install `git` and Ansible with `user_data`. The NAT gateway gives the private subnet the outbound internet it needs.

### 4.2 Configuration Management (25%)

**Everything runs from the controller, not your laptop** (slide 7). Your laptop only reaches the controller through SSM:

```bash
aws ssm start-session --target <controller-instance-id>
```

| Criterion | How to earn it | Evidence for the grader |
|---|---|---|
| **Controller (5)** | Ansible installed on `10.0.0.135`, repo cloned there, `inventory.ini` lists **private IPs only** (`10.0.0.5`, `10.0.0.136`) | `inventory.ini` and the playbooks in `ansible/` in the repo; `ansible all -m ping` output in the README |
| **Docker via Ansible (5)** | Role `geerlingguy.docker` in a playbook (see `grafana/playbook-stack.yaml`) | The playbook file |
| **Container (5)** | App runs as a container on the web server, port 80 mapped | `docker ps` output; the app URL |
| **ECR image (5)** | Multi-stage Dockerfile for `Infratify/ship` → build → push to `devops-bootcamp/final-project-<nama>` → web server pulls it | ECR console screenshot with the image tag |
| **Repeatable (5)** | Run every playbook **twice**; the second run must report `changed=0` | The second-run `PLAY RECAP` pasted in the README |

SSH key problem (plan it early): the controller needs a private key that matches the key pair on the web and monitoring servers. Options, from simple to clean:
1. Generate a project-only key pair, upload the public half through Terraform (`aws_key_pair`), and paste the private half onto the controller once over SSM. Simple, with one manual step to document.
2. Keep the private key in SSM Parameter Store (SecureString) and fetch it in `user_data`. No manual paste.
3. Skip SSH entirely and use Ansible's SSM connection. This also earns the "Ansible without port 22" bonus, but it needs more setup, so do it last.

Image build and push: do it on the controller, which is the least-privilege choice.
- The controller's IAM role gets `AmazonEC2ContainerRegistryPowerUser` (push).
- The web server's role gets `AmazonEC2ContainerRegistryReadOnly` (pull).
- The monitoring server's role needs only SSM.
- That split also covers the "IAM least privilege per server" bonus.

Idempotency traps (this is where the 5% is lost):
- `command` and `shell` tasks report `changed` every run. Add `creates:` or `changed_when: false` (as in `ansible2/playbook-disk.yaml`).
- `aws ecr get-login-password | docker login` is always "changed", so set `changed_when: false`.
- Prefer real modules (`community.docker.docker_image`, `docker_container`, `copy`, `template`, `apt`) over `command`.
- Ubuntu 24.04 has no `awscli` in apt. Install it with `snap install aws-cli --classic` or the official zip. Check this on a real server **(verify)**.

### 4.3 Monitoring & Observability (20%)

| Criterion | How to earn it |
|---|---|
| **Prometheus (8)** | Compose service as in `grafana/compose.yaml`, config bind-mounted from `prometheus.yaml`. Scrape `localhost:9090` and `10.0.0.5:9100`. In the UI, `/targets` shows both **UP** |
| **Dashboard (8)** | Grafana running with a Prometheus data source and your dashboard. Use a named volume `grafana-data` so it survives container removal (slide 9) |
| **Web server metrics (4)** | Panels for **CPU, memory and disk** (slide 11) |

Gotchas
- `grafana/dashboard.json` has **CPU, network and disk** panels, but the brief asks for **CPU, memory and disk**. Add a memory panel, for example:
  `100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)`
- That JSON references a data source by an ID from your old Grafana (`cg4ojmk48mio0d`), so a fresh Grafana will show "datasource not found". Fix it by choosing the new data source when importing, or by provisioning the data source with a fixed `uid` and editing the JSON to match. It was also exported from Grafana v13.3.1, so use the same version if the import complains **(verify)**.
- Inside Compose the data source URL is `http://prometheus:9090`, not `localhost`.
- node_exporter goes on the **web server** only (`playbook-exporter.yaml`). The metrics must come from there.
- Slide 16 says you submit **a Grafana login**. Set the admin password from a variable (`GF_SECURITY_ADMIN_PASSWORD`) kept out of git, using Ansible Vault or an env file.
- Don't copy the `grafana/` folder's SG rule that opens port 3000 to your IP. In this project Grafana must not be publicly reachable.

### 4.4 Domain & Secure Access (15%)

| Criterion | How to earn it |
|---|---|
| **Domain (5)** | `web.infratify.com` → A record to the web server's Elastic IP, proxied. SSL/TLS mode **Flexible** (Cloudflare to origin over HTTP port 80) |
| **Tunnel (7)** | Create a Cloudflare Tunnel; run `cloudflared` on the monitoring server; public hostname `monitoring.infratify.com` → Grafana (`http://grafana:3000` if `cloudflared` is in the same Compose file, or `http://localhost:3000` on host network) |
| **Not public (3)** | The monitoring server has **no** inbound rules to Grafana or Prometheus. Test: `curl http://<anything>:3000` and `:9090` from outside must time out |

Notes
- Reuse `terraform3/userdata-tunnel.sh` and `cloudflare2/notes.txt` (`ssl-mode: Flexible`).
- Keep the tunnel token **out of git**. Store it in SSM Parameter Store, as `terraform3` did, or in Ansible Vault, and pass it to the container as an environment variable.
- Outbound only: the tunnel dials out through the NAT gateway, which is why the private subnet needs it.
- **(confirm)** The slides use `*.infratify.com`, while your lessons used `ikhwannaufal.my`. Ask who controls DNS and the Cloudflare account for `infratify.com`, and how you get the records and tunnel created. Do not leave this to the last day.

### 4.5 Documentation (10%): the easiest 10 points

Repo layout (slide 12), in a **public** repo named `devops-bootcamp-project`:

```
devops-bootcamp-project/
├── app/            # Dockerfile + the Infratify/ship code
├── terraform/
├── ansible/
├── README.md
└── .github/workflows/pages.yaml
```

| Criterion | How to earn it |
|---|---|
| **GitHub Pages (3)** | Pages enabled with source "GitHub Actions"; a workflow publishes the README (from `cicd4/cicd1.md`: `permissions` with `pages: write` and `id-token: write`, upload artifact, deploy). A `GITHUB_TOKEN` without `pages: write` is the classic failure from your notes |
| **URLs (4)** | Top of the README: **App URL**, **Monitoring URL**, **Repo URL**. Make them clickable and keep them current |
| **Structured explanation (3)** | Sections: Overview → Architecture diagram → Prerequisites → Step-by-step (Terraform → Ansible → Monitoring → Domain) → **screenshots** for each rubric criterion → Troubleshooting |

Slide 12 asks for "step-by-step guide and screenshots for the third criterion". Screenshots to take (each proves a rubric row):
`terraform apply` output, VPC resource map, SG rules, 3 running instances, `ansible all -m ping`, second playbook run with `changed=0`, ECR image, app in browser via the domain, Prometheus `/targets` all UP, Grafana dashboard, `curl` failing against the monitoring server's raw IP, and the Pages site itself.

Use the Playwright setup from this session to automate the browser screenshots if you like.

---

## 5. Evidence checklist (print this before submission)

The grader sees only artifacts. For each row, make sure the proof exists **in the repo or the README**.

| Rubric row | Proof |
|---|---|
| S3 backend | `providers.tf` in repo; screenshot of the bucket |
| VPC | `network.tf`; console screenshot with the correct names |
| SGs | `security.tf`; console screenshot of both SGs |
| EC2 ×3 | `ec2.tf`; screenshot showing names, IPs, roles |
| Controller | `ansible/inventory.ini` with private IPs; ping output |
| Docker | Playbook with `geerlingguy.docker` |
| Container | `docker ps`; app URL loads |
| ECR | ECR console screenshot |
| Repeatable | `PLAY RECAP` with `changed=0` |
| Prometheus | `/targets` screenshot |
| Dashboard | Dashboard screenshot + the login submitted |
| Metrics | CPU, memory and disk panels visible with data |
| Domain | `web.infratify.com` loads the app |
| Tunnel | `monitoring.infratify.com` loads Grafana |
| Not public | Failed `curl` / port test against the raw IP |
| Pages | The live Pages URL |
| URLs | Top of the README |
| Explanation | The README structure above |

---

## 6. Bonus strategy (+22 max)

Only start after the base is working and documented. Ordered by **points per effort**:

| Order | Bonus | Pts | Effort | How |
|---|---|---|---|---|
| 1 | Code format checked (CI/CD) | +2 | Low | Add `terraform fmt -check` to the Pages workflow (or a new one) |
| 2 | Pages on your own domain | +2 | Low | Custom domain in Pages settings + a DNS record in Cloudflare |
| 3 | IAM least privilege per server | +2 | Low | Three separate roles: controller = ECR push, web = ECR pull, monitoring = SSM only (you already need this) |
| 4 | Full IaC coverage | +3 | Medium | Bring the ECR repo, IAM roles, key pair, SSM parameters and Elastic IP into Terraform (the state bucket stays manual) |
| 5 | Ansible without port 22 | +3 | Medium | Ansible's SSM connection plugin; then remove the port 22 rules |
| 6 | Plan gate on PR | +3 | Medium | Workflow runs `terraform plan` on `pull_request`; needs AWS credentials in Actions (OIDC preferred) |
| 7 | Push image to ECR from CI/CD | +3 | Medium | Build-push job; needs the same AWS credentials |
| 8 | Publish image to the web server from CI/CD | +4 | High | A self-hosted runner on the web server (see `cicd4/cicd4.md`) pulls and restarts the container |

Caution: items 6–8 put AWS credentials into GitHub. Use OIDC or tightly scoped secrets, never plain keys in the repo. Remember "CI/CD 1 only is mandatory", so these are optional.

---

## 7. Build order and time plan

The brief says 2 hours, and the review is about three weeks out. Do **one full dry run** well before the deadline: `terraform destroy`, then rebuild from the README alone. The goal is to finish the rebuild in under the time limit.

| Step | Work | Rubric points secured |
|---|---|---|
| 0 | Create public repo `devops-bootcamp-project`, `.gitignore` (state, keys, vault password, `*.tfvars`, tunnel token) | – |
| 1 | State bucket by hand, then `backend` + provider | 5 |
| 2 | VPC, route tables, IGW, NAT, exact names | 10 |
| 3 | Security groups | 5 |
| 4 | 3 × EC2, fixed IPs, Elastic IP, SSM profiles, controller `user_data` | 10 |
| 5 | Reach the controller over SSM; `ansible all -m ping` | 5 |
| 6 | Playbook: Docker role on all hosts | 5 |
| 7 | Dockerfile → ECR → container on the web server | 10 |
| 8 | Re-run all playbooks; fix every `changed` on the second run | 5 |
| 9 | node_exporter + monitoring Compose stack + dashboard (with memory panel) | 20 |
| 10 | DNS for the web app, Cloudflare Tunnel for Grafana, verify not public | 15 |
| 11 | README, screenshots, Pages workflow | 10 |
| 12 | Bonuses in the order from section 6 | up to +22 |

If time runs short, cut from the **bottom** (bonuses first, then polish). Never skip a whole section.

---

## 8. Keep-it-alive and cost

- The grader needs the **URLs and Grafana live at review time**. Deploy before the submission (24 hours earlier, slide 16) and leave it running until the review.
- The NAT gateway and Elastic IP are the main hourly costs. Outside the review window, `terraform destroy` and rebuild with the runbook. This is also your dry run.
- Set an AWS budget alert so a forgotten stack never surprises you.

---

## 9. Top ten ways to lose marks

1. Resource names that don't match slide 4 (VPC module defaults).
2. Port 9100 open to more than the monitoring server.
3. Grafana or Prometheus reachable from the internet.
4. A second Ansible run that still shows `changed`.
5. Running Ansible from your laptop instead of the controller.
6. A dashboard without a **memory** panel, or one showing "datasource not found".
7. The tunnel token, Grafana password, SSH key or `.tfstate` committed to the public repo.
8. Pages enabled but the workflow lacks `pages: write`, so the site shows 404.
9. URLs missing or stale in the README.
10. Skipping a section entirely, which breaks the pass rule.

---

## 10. Open questions for your instructors

1. Who owns DNS and the Cloudflare account for `infratify.com`, and how do you create records and tunnels there?
2. Does "all sections" mean a non-zero score in each, or a minimum percentage in each?
3. Where is **Appendix A** (the suggested build order mentioned on slide 16)? It was not in the 17 slides.
4. Is the review date really 15 September? That date has already passed relative to today.
5. Is the bonus capped, and is it added on top of 100 or limited to 100?
6. Which exact repo is `Infratify/ship`, and does it need a specific Node version or build command?
