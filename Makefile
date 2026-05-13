# GreymHatter Build System
#
# Prerequisites: packer, docker
# Install: brew install hashicorp/tap/packer
#
# Pipeline:
#   make base-amd64        Stage 1: ISO → Proxmox base template (run once)
#   make base-arm64        Stage 1: ISO → Fusion base VM (run once)
#   make build-amd64       Stage 2: Clone template → Ansible → final template
#   make build-arm64       Stage 2: Boot base VM → Ansible → final VM
#   make export-amd64      Stage 3: Proxmox template → OVA for distribution
#   make export-arm64      Stage 3: Fusion VM → OVA for distribution
#   make dev               Fast iteration: SCP + Ansible on a live VM
#
# Docs:
#   make docs              Preview MkDocs site at http://localhost:8000

.PHONY: help base-amd64 base-arm64 build-amd64 build-arm64 export-amd64 export-arm64 dev docs docs-build clean

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

export-amd64: ## Stage 3: Export Proxmox template → OVA (TODO: download disk from Proxmox)
	@echo "Export from Proxmox requires downloading the disk image first."
	@echo "Use: qm disk export <vmid> scsi0 /tmp/greymhatter.raw"
	@echo "Then: $(OVFTOOL) /tmp/greymhatter.vmx output/greymhatter-amd64.ova"

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
	cd packer/fusion && packer init greymhatter-fusion.pkr.hcl && \
	packer build -var 'headless=false' \
		-only='greymhatter.vmware-vmx.greymhatter-arm64' greymhatter-fusion.pkr.hcl

export-arm64: ## Stage 3: Fusion VM → OVA for distribution
	$(OVFTOOL) output/fusion-arm64/greymhatter-f42-arm64.vmx output/greymhatter-f42-arm64.ova
	@echo ""
	@echo "  OVA exported: output/greymhatter-f42-arm64.ova"
	@echo ""

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
