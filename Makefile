# GreymHatter Build System
#
# Prerequisites: packer, docker
# Install: brew install hashicorp/tap/packer
#
# Pipeline:
#   make base-amd64        Stage 1: ISO → Proxmox base template (run once)
#   make base-arm64        Stage 1: ISO → Fusion base VM (run once)
#   make base-esxi         Stage 1: ISO → ESXi base template (run once)
#   make build-amd64       Stage 2: Clone template → Ansible → Proxmox template
#   make build-arm64       Stage 2: Boot base VM → Ansible → Fusion final VM
#   make build-esxi        Stage 2: Clone base → Ansible → ESXi template
#   make export-amd64      Stage 3: Proxmox template → OVA for distribution
#   make export-arm64      Stage 3: Fusion VM bundle → zip for distribution
#   make export-esxi       Stage 3: ESXi template → OVA via ovftool
#   make dev               Fast iteration: SCP + Ansible on a live VM
#
# Docs:
#   make docs              Preview MkDocs site at http://localhost:8000

.PHONY: help base-amd64 base-arm64 base-esxi build-amd64 build-arm64 build-esxi export-amd64 export-arm64 export-esxi dev docs docs-build clean

# SSH config for dev workflow
SSH_KEY := crypto/greymhatter
SSH_OPTS := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -i $(SSH_KEY)

# ovftool path (ships with VMware Fusion)
OVFTOOL := /Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/ovftool

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# AMD64 (Proxmox)
# =============================================================================

base-amd64: ## Stage 1: ISO → Proxmox base template (run once)
	cd packer && packer init greymhatter.pkr.hcl && \
	packer build -only='base.proxmox-iso.fedora-base' .

build-amd64: ## Stage 2: Clone template → Ansible → Proxmox template
	cd packer && packer init greymhatter.pkr.hcl && \
	packer build -only='greymhatter.proxmox-clone.greymhatter' .

export-amd64: ## Stage 3: Proxmox template → OVA for ESXi / Workstation
	@mkdir -p output; \
	DATE=$$(date +%Y%m%d); N=1; \
	while [ -e output/greymhatter-f42-amd64-$$DATE.$$N.ova ]; do N=$$((N+1)); done; \
	OUT=output/greymhatter-f42-amd64-$$DATE.$$N.ova; \
	bash scripts/export-amd64-ova.sh $$OUT

# =============================================================================
# ESXi (AMD64) — Packer talks to ESXi via SSH-tunnelled vSphere API
# =============================================================================

base-esxi: ## Stage 1: ISO → ESXi base VM (run once; iteration uses build-esxi)
	cp packer/http/ks.cfg packer/esxi/ks.cfg
	cd packer/esxi && packer init greymhatter-esxi.pkr.hcl && \
	packer build -var-file=../packer.auto.pkrvars.hcl \
		-only='base.vsphere-iso.fedora-esxi-base' greymhatter-esxi.pkr.hcl
	rm -f packer/esxi/ks.cfg

build-esxi: ## Stage 2: Clone base VM → Ansible → final ESXi VM
	cp packer/http/ks.cfg packer/esxi/ks.cfg
	cd packer/esxi && packer init greymhatter-esxi.pkr.hcl && \
	packer build -var-file=../packer.auto.pkrvars.hcl \
		-only='greymhatter.vsphere-clone.greymhatter-esxi' greymhatter-esxi.pkr.hcl
	rm -f packer/esxi/ks.cfg

export-esxi: ## Stage 3: ESXi template → OVA via ovftool
	@mkdir -p output; \
	DATE=$$(date +%Y%m%d); N=1; \
	while [ -e output/greymhatter-f42-esxi-$$DATE.$$N.ova ]; do N=$$((N+1)); done; \
	OUT=output/greymhatter-f42-esxi-$$DATE.$$N.ova; \
	ESX_URL=$$(awk -F'"' '/^esx_url/{print $$2}' packer/packer.auto.pkrvars.hcl); \
	ESX_USER=$$(awk -F'"' '/^esx_username/{print $$2}' packer/packer.auto.pkrvars.hcl); \
	ESX_PASS=$$(awk -F'"' '/^esx_password/{print $$2}' packer/packer.auto.pkrvars.hcl); \
	ESX_HOST=$$(echo "$$ESX_URL" | sed -E 's|https?://||'); \
	VM=greymhatter-f42-esxi-$$(date +%Y%m%d); \
	ENC_USER=$$(printf '%s' "$$ESX_USER" | python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(), safe=""))'); \
	ENC_PASS=$$(printf '%s' "$$ESX_PASS" | python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(), safe=""))'); \
	$(OVFTOOL) --noSSLVerify "vi://$$ENC_USER:$$ENC_PASS@$$ESX_HOST/$$VM" $$OUT
	@echo ""
	@echo "  OVA exported: output/greymhatter-f42-esxi-*.ova"
	@echo ""

# =============================================================================
# ARM64 (VMware Fusion) — runs Packer natively on Mac
# =============================================================================

base-arm64: ## Stage 1: ISO → Fusion base VM (run once)
	cp packer/http/ks.cfg packer/fusion/ks.cfg
	cd packer/fusion && packer init greymhatter-fusion.pkr.hcl && \
	packer build -var 'headless=false' \
		-only='base.vmware-iso.fedora-arm64-base' greymhatter-fusion.pkr.hcl
	rm -f packer/fusion/ks.cfg

build-arm64: ## Stage 2: Boot base VM → Ansible → final VM
	@MAXMIND_ID=$$(grep '^maxmind_account_id' packer/packer.auto.pkrvars.hcl 2>/dev/null | awk -F'"' '{print $$2}'); \
	MAXMIND_KEY=$$(grep '^maxmind_license_key' packer/packer.auto.pkrvars.hcl 2>/dev/null | awk -F'"' '{print $$2}'); \
	DOCKER_USER=$$(grep '^docker_hub_username' packer/packer.auto.pkrvars.hcl 2>/dev/null | awk -F'"' '{print $$2}'); \
	DOCKER_TOKEN=$$(grep '^docker_hub_token' packer/packer.auto.pkrvars.hcl 2>/dev/null | awk -F'"' '{print $$2}'); \
	DOCKER_MIRROR=$$(grep '^docker_registry_mirror' packer/packer.auto.pkrvars.hcl 2>/dev/null | awk -F'"' '{print $$2}'); \
	GITHUB_TOKEN=$$(grep '^github_token' packer/packer.auto.pkrvars.hcl 2>/dev/null | awk -F'"' '{print $$2}'); \
	cd packer/fusion && packer init greymhatter-fusion.pkr.hcl && \
	packer build -var 'headless=false' \
		-var "maxmind_account_id=$$MAXMIND_ID" \
		-var "maxmind_license_key=$$MAXMIND_KEY" \
		-var "docker_hub_username=$$DOCKER_USER" \
		-var "docker_hub_token=$$DOCKER_TOKEN" \
		-var "docker_registry_mirror=$$DOCKER_MIRROR" \
		-var "github_token=$$GITHUB_TOKEN" \
		-only='greymhatter.vmware-vmx.greymhatter-arm64' greymhatter-fusion.pkr.hcl

export-arm64: ## Stage 3: Fusion VM bundle → .vmwarevm zip for distribution
	@# OVA can't be used here: ovftool has no ARM osType in its mapping table,
	@# so any OVA imported into Fusion ends up with guestos="other" and refuses
	@# to power on ("requires x86 machine architecture"). Ship the .vmwarevm
	@# bundle directly so the original guestos="arm-fedora-64" is preserved.
	@DATE=$$(date +%Y%m%d); N=1; \
	while [ -e output/greymhatter-f42-arm64-$$DATE.$$N.zip ]; do N=$$((N+1)); done; \
	OUT=greymhatter-f42-arm64-$$DATE.$$N.zip; \
	sed -i.bak 's/^displayname = "Clone of greymhatter-f42-arm64-base"$$/displayname = "greymhatter-f42-arm64"/' output/fusion-arm64/greymhatter-f42-arm64.vmx && \
	rm -f output/fusion-arm64/greymhatter-f42-arm64.vmx.bak && \
	cd output && mv fusion-arm64 greymhatter-f42-arm64.vmwarevm && \
	zip -r $$OUT greymhatter-f42-arm64.vmwarevm && \
	mv greymhatter-f42-arm64.vmwarevm fusion-arm64; \
	echo ""; \
	echo "  Bundle exported: output/$$OUT"; \
	echo "  Recipients: extract, then double-click the .vmx file in Fusion."; \
	echo ""

# =============================================================================
# Dev workflow — fast iteration on a live VM
# =============================================================================

dev: ## SCP repo + run Ansible + reboot (usage: make dev DEV_VM_IP=<ip>)
	@if [ -z "$(DEV_VM_IP)" ]; then \
		echo ""; \
		echo "  Usage: make dev DEV_VM_IP=<ip-of-your-dev-vm>"; \
		echo ""; \
		exit 1; \
	fi
	@echo "==> Copying repo to $(DEV_VM_IP)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo rm -rf /tmp/greymhatter && sudo mkdir -p /tmp/greymhatter && sudo chown hatter /tmp/greymhatter'
	scp $(SSH_OPTS) -r ansible hatter@$(DEV_VM_IP):/tmp/greymhatter/ansible
	scp $(SSH_OPTS) -r media hatter@$(DEV_VM_IP):/tmp/greymhatter/media
	@echo "==> Running Ansible playbook..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'cd /tmp/greymhatter && sudo ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --extra-vars greymhatter_repo_path=/tmp/greymhatter'
	@echo "==> Rebooting VM..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo reboot' || true
	@echo ""
	@echo "  VM is rebooting. Log in at $(DEV_VM_IP) in ~30 seconds."
	@echo ""

# =============================================================================
# Testing — run against a deployed VM
# =============================================================================

test: ## Run automated integration tests (usage: make test DEV_VM_IP=<ip>)
	@if [ -z "$(DEV_VM_IP)" ]; then \
		echo ""; \
		echo "  Usage: make test DEV_VM_IP=<ip>"; \
		echo "  Options: TEST=test1|test2|test3|all (default: all)"; \
		echo ""; \
		exit 1; \
	fi
	@echo "==> Uploading test data to $(DEV_VM_IP)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo mkdir -p /opt/share/test-data && sudo chown hatter /opt/share/test-data' || \
	sshpass -p 'H@tt3r123!' ssh -o StrictHostKeyChecking=no hatter@$(DEV_VM_IP) 'sudo mkdir -p /opt/share/test-data && sudo chown hatter /opt/share/test-data'
	@for f in tests/*.zip; do \
		echo "  Copying $$f..."; \
		scp $(SSH_OPTS) "$$f" hatter@$(DEV_VM_IP):/opt/share/test-data/ 2>/dev/null || \
		sshpass -p 'H@tt3r123!' scp -o StrictHostKeyChecking=no "$$f" hatter@$(DEV_VM_IP):/opt/share/test-data/; \
	done
	@echo "==> Uploading test script..."
	scp $(SSH_OPTS) tests/run-tests.sh hatter@$(DEV_VM_IP):/opt/share/test-data/ 2>/dev/null || \
	sshpass -p 'H@tt3r123!' scp -o StrictHostKeyChecking=no tests/run-tests.sh hatter@$(DEV_VM_IP):/opt/share/test-data/
	@echo "==> Running tests..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo bash /opt/share/test-data/run-tests.sh --$(TEST)' 2>/dev/null || \
	sshpass -p 'H@tt3r123!' ssh -o StrictHostKeyChecking=no hatter@$(DEV_VM_IP) 'sudo bash /opt/share/test-data/run-tests.sh --$(TEST)'

test-manual: ## Run tests with verbose output for manual verification (usage: make test-manual DEV_VM_IP=<ip>)
	@if [ -z "$(DEV_VM_IP)" ]; then \
		echo ""; \
		echo "  Usage: make test-manual DEV_VM_IP=<ip>"; \
		echo "  Options: TEST=test1|test2|test3|all (default: all)"; \
		echo ""; \
		exit 1; \
	fi
	@echo "==> Uploading test data to $(DEV_VM_IP)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo mkdir -p /opt/share/test-data && sudo chown hatter /opt/share/test-data' || \
	sshpass -p 'H@tt3r123!' ssh -o StrictHostKeyChecking=no hatter@$(DEV_VM_IP) 'sudo mkdir -p /opt/share/test-data && sudo chown hatter /opt/share/test-data'
	@for f in tests/*.zip; do \
		echo "  Copying $$f..."; \
		scp $(SSH_OPTS) "$$f" hatter@$(DEV_VM_IP):/opt/share/test-data/ 2>/dev/null || \
		sshpass -p 'H@tt3r123!' scp -o StrictHostKeyChecking=no "$$f" hatter@$(DEV_VM_IP):/opt/share/test-data/; \
	done
	@echo "==> Uploading test script..."
	scp $(SSH_OPTS) tests/run-tests.sh hatter@$(DEV_VM_IP):/opt/share/test-data/ 2>/dev/null || \
	sshpass -p 'H@tt3r123!' scp -o StrictHostKeyChecking=no tests/run-tests.sh hatter@$(DEV_VM_IP):/opt/share/test-data/
	@echo "==> Running tests (verbose)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo bash /opt/share/test-data/run-tests.sh --$(TEST) --verbose' 2>/dev/null || \
	sshpass -p 'H@tt3r123!' ssh -o StrictHostKeyChecking=no hatter@$(DEV_VM_IP) 'sudo bash /opt/share/test-data/run-tests.sh --$(TEST) --verbose'

# Default test scope
TEST ?= all

# =============================================================================
# Verify — manifest-driven assertions against a deployed VM
# =============================================================================

verify: ## Run verify role only (fast, skips deep checks). Usage: make verify DEV_VM_IP=<ip>
	@if [ -z "$(DEV_VM_IP)" ]; then \
		echo ""; \
		echo "  Usage: make verify DEV_VM_IP=<ip>"; \
		echo "  Skips docker_startable deep checks for inner-loop speed."; \
		echo "  Use 'make verify-deep' for full end-to-end verification."; \
		echo ""; \
		exit 1; \
	fi
	@echo "==> Uploading ansible/ to $(DEV_VM_IP)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo rm -rf /tmp/greymhatter && sudo mkdir -p /tmp/greymhatter && sudo chown hatter /tmp/greymhatter'
	scp $(SSH_OPTS) -r ansible hatter@$(DEV_VM_IP):/tmp/greymhatter/ansible
	@echo "==> Running verify role (verify_deep=false)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'cd /tmp/greymhatter && sudo ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --tags verify --extra-vars "greymhatter_repo_path=/tmp/greymhatter verify_deep=false"'

verify-deep: ## Run verify with full startable-service deep checks. Usage: make verify-deep DEV_VM_IP=<ip>
	@if [ -z "$(DEV_VM_IP)" ]; then \
		echo ""; \
		echo "  Usage: make verify-deep DEV_VM_IP=<ip>"; \
		echo "  Brings up Timesketch/Yeti/SpiderFoot, probes them, takes them down."; \
		echo ""; \
		exit 1; \
	fi
	@echo "==> Uploading ansible/ to $(DEV_VM_IP)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo rm -rf /tmp/greymhatter && sudo mkdir -p /tmp/greymhatter && sudo chown hatter /tmp/greymhatter'
	scp $(SSH_OPTS) -r ansible hatter@$(DEV_VM_IP):/tmp/greymhatter/ansible
	@echo "==> Running verify role (verify_deep=true)..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'cd /tmp/greymhatter && sudo ansible-playbook -i ansible/inventory/local.ini ansible/playbook.yml --tags verify --extra-vars "greymhatter_repo_path=/tmp/greymhatter verify_deep=true"'

smoke: ## Run test0 container smoke test only (<60s). Usage: make smoke DEV_VM_IP=<ip>
	@if [ -z "$(DEV_VM_IP)" ]; then \
		echo ""; \
		echo "  Usage: make smoke DEV_VM_IP=<ip>"; \
		echo ""; \
		exit 1; \
	fi
	@echo "==> Uploading test script..."
	scp $(SSH_OPTS) tests/run-tests.sh hatter@$(DEV_VM_IP):/tmp/run-tests.sh
	@echo "==> Running test0..."
	ssh $(SSH_OPTS) hatter@$(DEV_VM_IP) 'sudo bash /tmp/run-tests.sh --test0'

# =============================================================================
# Documentation
# =============================================================================

docs: ## Preview MkDocs site at http://localhost:8000
	docker compose up mkdocs

docs-build: ## Build static MkDocs site
	docker compose run --rm mkdocs build

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Remove build output directories
	rm -rf output/ packer/output/ packer/packer-outputs/
