# Final Project Prep: How This Repo Evolved (Aug 25 → Nov 18, 2026)

This repo is a learning diary. Each folder is one lesson, and each lesson builds on the one before it. The `grafana/` folder is the newest and contains almost everything you learned. If you understand `grafana/`, you understand the whole bootcamp.

**The one-sentence story:** do it by hand → write it down as code → let tools configure it → watch it run.

---

## 1. The big picture

```
 Git ──► AWS ──► Cloudflare ──► Docker ──► CI/CD ──► Terraform ──► Ansible ──► Prometheus ──► Grafana
 track   cloud   reach it       package    automate   create the   configure   collect        visualise
 changes basics  from internet  apps       delivery   servers      servers     metrics        + alert
```

| Layer | Question it answers | Tool |
|---|---|---|
| Version control | "What changed, and who changed it?" | Git / GitHub |
| Infrastructure (manual) | "Where does my app run?" | AWS console + CLI |
| Networking / edge | "How do users reach it safely?" | Cloudflare |
| Packaging | "How do I ship the app the same way everywhere?" | Docker, Compose |
| Delivery | "How do changes reach production automatically?" | GitHub Actions |
| Infrastructure as Code | "How do I create servers repeatably?" | Terraform |
| Configuration management | "How do I set up what's *inside* the servers?" | Ansible |
| Observability | "Is it healthy? Tell me when it isn't." | Prometheus, Grafana, Discord |

---

## 2. Timeline (all merged work, oldest first)

The repo has 40 commits (36 non-merge). The table groups them by lesson.

| Date (2026) | Commit(s) | Folder | New concept | Builds on |
|---|---|---|---|---|
| Aug 25 | `8053b2b` … `7f18cf9` | root | `git init/add/commit`, `.gitignore`, README, notes | nothing |
| Aug 26 | `41b5b59` … `a95e5f5` | root | Branches and merges (`tambah-notes`, `fix-tajuk`) | local Git |
| Sep 2 | `93880c4` … `6baa26e` | root | Clone, edit from two copies, pull request (#2) | branches |
| Sep 7 | `5b37891` (#3) | `aws1/` | IAM user + AWS CLI (`sts get-caller-identity`) | – |
| Sep 14 | `a298454` (#4) | `aws2/` | EC2 + IAM role + SSM + S3 | IAM |
| Sep 14 | `363b7bb` (#5) | `aws3/` | VPC, subnet, route table | EC2 |
| Sep 16 | `e0417fe` (#6) | `aws4/` | ECR, NAT Gateway, Elastic IP | VPC |
| Sep 21 | `1106eef` (#7) | `cloudflare1/` | DNS, Cloudflare Pages | domain basics |
| Sep 26 | `04d332d` (#8) | `cloudflare2/` | Origin, proxy, tunnel, SSL mode | Elastic IP |
| Sep 28 | `cad3904` (#9) | `docker1/` | Containers and images | – |
| Oct 2 | `1575563` (#10) | `docker2/` | Dockerfile, multi-stage build | images |
| Oct 5 | `e99f1c3` (#11) | `docker3/` | ECR push, volumes, networks | ECR (aws4) |
| Oct 7 | `d83bec9`, `0c673ed` (#12) | `docker4/` | Docker Compose | volumes, networks |
| Oct 25 | `1c44a1b`, `79d1686`, `4436820`, `11c7b6f` (#13–16) | `cicd4/` | GitHub Actions, gate, secrets, GHCR, self-hosted runner | Docker, EC2 |
| Oct 26 | `5e4fea1` (#17) | `terraform1/` | HCL, provider, `apply` (VPC + SG) | aws3 |
| Oct 28 | `9d9d649` (#18) | `terraform2/` | S3 remote state, variables, private subnet | terraform1 |
| Nov 3 | `769b30c` (#19) | `terraform3/` | Registry modules, NAT, user_data, tunnel | terraform2, cloudflare2 |
| Nov 4 | `84994a5` (#20) | `terraform4/` | Rackula app on EC2 via Compose | terraform3, docker4 |
| Nov 9 | `744f1b1` (#21) | `ansible1/` | Inventory, ad-hoc, first playbook | terraform4 |
| Nov 11 | `fa6c871` (#22) | `ansible2/` | Variables, templates, handlers, disk | ansible1 |
| Nov 16 | `a2e80c4` (#23) | `prometheus/` | Galaxy roles, node_exporter, Prometheus | ansible2 |
| Nov 18 | `47c7e19` (#24) | `grafana/` | Compose stack, dashboard, Discord alert | prometheus |

Note the change of rhythm. Until PR #3 you were learning the tools. From PR #3 onward every lesson is a numbered pull request, which is the workflow you will use in a real team.

---

## 3. Phase-by-phase evolution

### Phase 1: Git (Aug 25 – Sep 2)
- `notes.md`: "Read = git log + git diff", "Branch = a timeline branch".
- `README.md` was edited from several places on purpose, to practise merges and clones.
- `CONTRIBUTING.md` arrived through a **pull request**, so you saw the GitHub flow for the first time.
- **Keep:** commit small, branch for each change, merge through a PR.

### Phase 2: AWS by hand (Sep 7 – Sep 16)
Nothing here is code. The `notes.txt` files only keep the *output* of CLI commands.
- **aws1:** an IAM user, and `aws sts get-caller-identity` to prove the CLI works.
- **aws2:** an EC2 instance, an IAM role so that **SSM** can open a shell without SSH, and an S3 bucket.
- **aws3:** a VPC (`10.0.0.0/16`), subnets and route tables. You inspected the default VPC (`172.31.0.0/16`) next to your own.
- **aws4:** ECR (a private image registry), a NAT Gateway (private subnets reach out), and an Elastic IP.
- **Why it matters:** Terraform later recreates exactly these pieces. You can only write the code if you already know what the pieces are.

### Phase 3: Cloudflare (Sep 21 – Sep 26)
- **cloudflare1:** DNS and Pages. Your domain (`ikhwannaufal.my`) points at Cloudflare nameservers.
- **cloudflare2:** an A record to the Elastic IP, **proxied**; SSL mode **Flexible**; and a **tunnel**.
- **Key idea:** a tunnel connects *outward* from the server, so the server needs no open inbound port. You reused this in `terraform3/userdata-tunnel.sh`.

### Phase 4: Docker (Sep 28 – Oct 7)
- **docker1:** `docker run`, `docker ps`, port mapping (`8080->80`).
- **docker2:** the multi-stage `Dockerfile`. Stage 1 (`node:20`) builds the site, and stage 2 (`nginx:alpine`) serves only `/app/dist`. Result: **1.26 GB (`app:v1`) → 68.8 MB (`app:v2`)**.
- **docker3:** `docker login` to ECR, tag, push; named volume `me`; custom network `arena`.
- **docker4:** `compose.yaml` runs redis (with a volume) plus an app (`depends_on`). `docker compose down` leaves the volume `me` in place.
- **Pattern to remember:** `image` + `ports` + `volumes` + `environment` + `depends_on`. You will see it again in `grafana/compose.yaml`.

### Phase 5: CI/CD (Oct 25) – folder `cicd4/`
The folder holds four notes: `cicd1.md` … `cicd4.md`. They have no workflow files, only the theory.
1. **Anatomy:** workflow › job › step; `on`, `runs-on`, `uses` vs `run`; Pages needs `permissions`.
2. **Gate:** a `test` step that fails stops the pipeline (exit code 1). Use `needs` to chain jobs. Each job gets a fresh runner.
3. **Secrets vs variables:** `secrets.X` is masked, `vars.X` is plain. Never put tokens in code, because git history keeps them. Use `pull_request` with `types` and `if` so that test runs on PRs and deploy runs on merge.
4. **GHCR + self-hosted runner:** `packages: write`, `login-action`, `build-push-action`. The runner on EC2 pulls and runs the image. It connects outward, so no new port is needed.
- **Chain:** push → gate → build → registry → server.

### Phase 6: Terraform (Oct 26 – Nov 4)
Four steps, each with a clear new idea:

| Step | Added | Why it matters |
|---|---|---|
| `terraform1` | `providers.tf` (version pins), VPC, subnet, IGW, route table, SG | Resources reference each other (`aws_vpc.my_vpc.id`), which builds the dependency graph |
| `terraform2` | `backend "s3"` with `use_lockfile`, `variables.tf` (`var.az`), a private subnet, `ec2.tf`, `outputs.tf`, an SSM profile as a `data` source | Remote state lets you work from anywhere without clobbering; variables remove duplication |
| `terraform3` | `terraform-aws-modules` for the VPC, SG and EC2; `enable_nat_gateway`; `templatefile("userdata.sh")`; an SSM parameter holding the tunnel token | Modules shrink ~60 lines of network code to ~12; secrets come from SSM, not from code |
| `terraform4` | `create_iam_instance_profile` inside the module, `user_data_replace_on_change`, a Compose file fetched in user_data | One apply gives a running app on port 8080 |

### Phase 7: Ansible (Nov 9 – Nov 11)
Terraform builds the machines and Ansible configures them.
- **ansible1:** the bridge between the two tools is `inventory.tf`. It uses `local_file` plus `inventory.ini.tftpl` to write `inventory.ini` with the new public IPs (the file is in `.gitignore`). `ansible.cfg` sets the inventory, turns off host-key checking, and sets the Python interpreter. The playbook installs nginx, enables it, and writes an `index.html`. SSH is now open, but only to your IP (`data.http.myip` → `/32`).
- **ansible2:** `vars`, **Jinja2 templates** (`index.html.j2`, `nginx-site.conf.j2`), and **handlers** (`notify: Restart nginx` restarts only when the config really changed). `playbook-disk.yaml` grows the partition and filesystem, with `changed_when` and `failed_when` to keep it **idempotent** (rc 2 from `growpart` means "nothing to do").
- **Remember:** ad-hoc = one-off command (`ansible nodes -m ping`); playbook = repeatable plan.

### Phase 8: Prometheus (Nov 16)
- Disks grow to 16 GB (`root_block_device`), and the SG gets two new rules: **9090** (your IP) and **9100** (only the VPC, `10.20.0.0/16`).
- `playbook-exporter.yaml` runs the Galaxy role `prometheus.prometheus.node_exporter` on **all** nodes. `playbook-prometheus.yaml` runs the role `prometheus.prometheus.prometheus` on **node1 only**, with `prometheus_scrape_configs` pointing at the exporters.
- **Concepts:** exporters expose metrics on `:9100`; Prometheus **pulls (scrapes)** them; **gauge** (goes up and down, e.g. free disk) vs **counter** (only increases, e.g. CPU seconds; wrap with `rate()`).

### Phase 9: Grafana (Nov 18) – the latest folder
This folder is a copy of `prometheus/` plus a few changes:

| Change | File | Reason |
|---|---|---|
| `t3.micro` → `t3.small` | `ec2.tf` | Prometheus and Grafana in containers need more RAM |
| New SG rule, port 3000, your IP only | `security.tf` | Grafana UI |
| New backend key `grafana/terraform.tfstate` | `providers.tf` | Separate state per folder |
| New `playbook-stack.yaml` | – | Installs Docker (`geerlingguy.docker`), copies `prometheus.yaml` and `compose.yaml` to `/opt/monitoring`, runs `docker compose up -d` |
| New `compose.yaml` | – | `prom/prometheus` (9090, config bind-mounted) and `grafana/grafana` (3000, volume `grafana-data`), both `restart: unless-stopped` |
| New `prometheus.yaml` | – | Scrape config with a 15s interval (now a mounted file, not a role variable) |
| New `dashboard.json` | – | Dashboard "Armada Node Overview": **CPU busy %** `100 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))*100`, **Network receive** `rate(node_network_receive_bytes_total[5m])`, **Disk free on /** `node_filesystem_avail_bytes{mountpoint="/"}` |
| Discord alert | UI only | The contact point and alert rule are *not* stored in the repo |

The key architectural shift: Prometheus moved from a **role installed on the host** (prometheus folder) to a **container** (grafana folder), so one Compose file now runs the whole monitoring stack.

---

## 4. The capstone architecture (`grafana/` today)

```
   You (laptop)
     │ terraform apply
     ▼
 ┌────────────────────────── AWS ap-southeast-1 ──────────────────────────┐
 │  S3 bucket: remote state  (bootcamp-2026-ikhwannaufal)                 │
 │                                                                         │
 │  VPC 10.20.0.0/16 ── public subnet 10.20.1.0/24 ── IGW                  │
 │                                                                         │
 │   node1 (t3.small)                         node2 (t3.small)             │
 │   ├ node_exporter :9100  ◄─────scrape───┐  ├ node_exporter :9100        │
 │   ├ Docker Compose (/opt/monitoring)    │  └ nginx :80                  │
 │   │   ├ Prometheus :9090 ───────────────┘                               │
 │   │   └ Grafana    :3000 ──► Discord alert                              │
 │   └ nginx :80                                                           │
 │                                                                         │
 │  SG: 80 open │ 22, 9090, 3000 = my IP /32 │ 9100 = VPC only            │
 └─────────────────────────────────────────────────────────────────────────┘
        ▲
        │ ansible-playbook (SSH)  ◄── inventory.ini written by Terraform
```

**Order of operations:** Terraform → inventory.ini → Ansible disk → web → exporter → prometheus/stack → open Grafana → import dashboard → set Discord alert.

---

## 5. Threads that run through the whole repo

1. **Manual → scripted → declarative.** AWS console → CLI → `user_data` → Terraform → Ansible. At each step you took away one thing that a human had to remember.
2. **Least privilege on the network.** `0.0.0.0/0` only for HTTP; your IP `/32` for admin ports; the VPC CIDR for internal ports (9100). SSM and tunnels avoid inbound ports completely.
3. **Never put secrets in code.** SSM parameter (tunnel token), `secrets.*` in Actions, `.gitignore` for `inventory.ini`, `.env`, `*.tfstate`.
4. **Idempotency.** Terraform `plan` shows the diff, and Ansible modules say `changed` vs `ok`. Run it twice and nothing breaks.
5. **State.** Terraform state lives in S3 (one key per folder). Ansible is stateless, so the inventory has to be regenerated.
6. **Reuse.** Registry modules (Terraform), Galaxy roles (Ansible), public images (Docker). You rarely write the whole thing yourself.
7. **Folder-per-lesson.** Each Terraform and Ansible folder is a full copy of the previous one with one idea added. This is easy for learning, but in a real project you would use one folder and Git history.

---

## 6. Runbook: rebuild the grafana stack from zero

Prerequisites: AWS CLI logged in, Terraform ≥ 1.15, Ansible, an SSH key at `~/.ssh/id_ed25519`, the AWS key pair `ikhwannaufal-key` in `ap-southeast-1`, the S3 state bucket, and the IAM profile `EC2-SSM-Role`.

```bash
cd grafana

# 1. Infrastructure
terraform init
terraform plan
terraform apply            # also writes inventory.ini
terraform output           # note node1_ip / node2_ip + private IPs

# 2. Fix the IPs (see gotcha #1)
#    Put the two PRIVATE IPs in prometheus.yaml AND playbook-prometheus.yaml

# 3. Check connectivity
ansible nodes -m ping

# 4. Configure (order matters)
ansible-playbook playbook-disk.yaml
ansible-playbook playbook-web.yaml
ansible-playbook playbook-exporter.yaml
ansible-galaxy collection install prometheus.prometheus   # only if the role is missing
ansible-galaxy role install geerlingguy.docker            # only if the role is missing
ansible-playbook playbook-stack.yaml

# 5. Verify
#    http://<node1_ip>:9090/targets   → both node_exporter targets UP
#    http://<node1_ip>:3000           → Grafana (admin / admin on first login, change it)
#    Add data source: http://prometheus:9090 (same Compose network)
#    Dashboards → Import → dashboard.json

# 6. Clean up (avoid cost!)
terraform destroy
```

(The Prometheus URL for Grafana: both containers share a Compose network, so `http://prometheus:9090` works. `localhost` would not.)

---

## 7. Gotchas and weak spots I found in the repo

Fix or at least understand these before the final project.

1. **Hard-coded IPs go stale.** `grafana/prometheus.yaml` has `10.20.1.43` / `10.20.1.214`, while `grafana/playbook-prometheus.yaml` has `10.20.1.103` / `10.20.1.127`. They disagree with each other, and both change after every `terraform apply`. Better: render `prometheus.yaml` from a template using the Terraform private IP outputs, or use `groups['nodes']` in Ansible.
2. **Two Prometheus installs in one folder.** `playbook-prometheus.yaml` (a role on the host) and the Compose Prometheus both use port 9090. If you run both, the second one fails to bind. Pick one (the Compose one is the newer idea).
3. **`terraform2/outputs.tf`** prints `public_ip` for the private server. That is always empty, so use `private_ip`.
4. **Security:** `host_key_checking = False` and `curl ifconfig.me` for your IP are fine for a lab, but your IP changes and then SSH/Grafana lock you out. Re-run `terraform apply` to refresh the rule.
5. **Account identifiers:** `aws1/identity.txt` and the `aws*/notes.txt` files contain your real AWS account ID, user ID and ECR URL. They are in git history, so be careful if the repo is public. `.env` and `debug.log` are git-ignored (good), but `opencode.json` is tracked.
6. **Alerts are not in code.** The Discord contact point and the alert rule live only in Grafana's database (the `grafana-data` volume). If you destroy the server, the alert is gone. For the final project, consider Grafana provisioning files for the data source, dashboard and alert rules.
7. **`cicd4/cicd4.md`** has one section ("Two roles") flagged for a re-check against the original slide.
8. **Notes only, no workflow files.** `cicd4/` has no `.github/workflows/*.yaml`, so you have read about CI/CD but have not stored a working pipeline in this repo. Writing one is the biggest gap.
9. **Terraform/Ansible lock files:** `.terraform.lock.hcl` is committed (good, it pins provider versions), but the `.terraform/` folders are ignored (good).

---

## 8. Final project readiness checklist

Tick each one only if you can do it without looking.

**Git / GitHub**
- [ ] Create a branch, open a PR, and merge it
- [ ] Explain why a secret that was committed and then deleted is still exposed

**AWS**
- [ ] Draw the VPC → subnet → route table → IGW/NAT picture from memory
- [ ] Explain why SSM or a tunnel is safer than opening port 22

**Docker / Compose**
- [ ] Write a multi-stage Dockerfile and say why it is smaller
- [ ] Write a Compose file with a volume, a port and `depends_on`
- [ ] Say what survives `docker compose down` (volumes do)

**CI/CD**
- [ ] Write a workflow with a test job, a deploy job and `needs`
- [ ] Say when to use `secrets` vs `vars`
- [ ] Say why a self-hosted runner needs no inbound port

**Terraform**
- [ ] Explain init / plan / apply / destroy and what the state file is
- [ ] Use a module, a variable, an output, a data source
- [ ] Say why remote state needs locking (`use_lockfile`)

**Ansible**
- [ ] Write an inventory, an ad-hoc command and a playbook
- [ ] Use a variable, a template, a handler, a role from Galaxy
- [ ] Explain idempotency, and `changed_when` / `failed_when`

**Prometheus / Grafana**
- [ ] Explain pull vs push, exporters, and gauge vs counter
- [ ] Write a PromQL query using `rate()` and `avg by(...)`
- [ ] Build a dashboard and set up an alert to Discord

### Self-test questions
1. Why does `rate()` go around `node_cpu_seconds_total`, but not around `node_filesystem_avail_bytes`?
2. Why is port 9100 open to `10.20.0.0/16` and not to `0.0.0.0/0`?
3. What links Terraform to Ansible in this repo, and what breaks if you skip it?
4. Why does a handler run only when a task reports `changed`?
5. What would you change so that `terraform destroy && terraform apply` needs **no manual edits** afterwards?
6. Why does Grafana reach Prometheus at `prometheus:9090` and not at `localhost:9090`?

### Stretch goals (these make a strong final project)
- Put the whole flow in **one CI/CD pipeline**: `terraform plan` on PR, `apply` on merge, then `ansible-playbook`.
- Template `prometheus.yaml` from Terraform outputs, or use Ansible dynamic inventory (`groups['nodes']`).
- Provision the Grafana data source, dashboard and Discord alert from files.
- Turn the playbooks into **roles** and encrypt secrets with **Ansible Vault**.
- Add HTTPS with Cloudflare in front of Grafana (tunnel, no inbound port).
- Add tags and a budget alarm so that the lab never surprises you on the bill.

---

## 9. Glossary of the Malay terms in your notes

| Malay | English |
|---|---|
| nota | notes |
| amali | practical / hands-on exercise |
| tujuan, objektif | goal, objective |
| lancar / terbit | deploy / publish |
| bina | build |
| pasang | install |
| hidupkan | start / enable |
| naikkan | bring up (a container) |
| halang | block / prevent |
| kebenaran | permission |
| simpan | store |
| gudang | warehouse (registry in the restaurant metaphor) |
| cawangan | branch (the server in the metaphor) |
| besarkan | enlarge (resize disk) |
| sediakan | prepare / provision |
| pemantauan | monitoring |
