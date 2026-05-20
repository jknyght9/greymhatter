# Adding Tools

## Process

1. Create a task file in `ansible/roles/tools/tasks/`
2. Include it in `ansible/roles/tools/tasks/main.yml`
3. Pin the version in `ansible/group_vars/all/defaults.yml` (if applicable)
4. Update `docs/docs/tools/overview.md`
5. Test on both AMD64 and ARM64

## Task File Patterns

### Binary download (GitHub release)

```yaml
---
- name: Check if tool is installed
  ansible.builtin.stat:
    path: "{{ tools_dir }}/tool-name"
  register: tool_check

- name: Install tool
  when: not tool_check.stat.exists
  block:
    - name: Get latest release
      ansible.builtin.uri:
        url: https://api.github.com/repos/org/repo/releases/tags/v{{ tool_version }}
        return_content: true
      register: release

    - name: Download binary
      ansible.builtin.unarchive:
        src: "{{ download_url }}"
        dest: "{{ tools_dir }}"
        remote_src: true

    - name: Symlink to user bin
      ansible.builtin.file:
        src: "{{ tools_dir }}/tool-name"
        dest: "{{ user_local_bin }}/tool-name"
        state: link
        owner: "{{ greymhatter_username }}"
```

### Git clone

```yaml
---
- name: Check if tool is installed
  ansible.builtin.stat:
    path: "{{ tools_dir }}/tool-name/README.md"
  register: tool_check

- name: Clone tool
  ansible.builtin.git:
    repo: https://github.com/org/repo.git
    dest: "{{ tools_dir }}/tool-name"
    depth: 1
  become_user: "{{ greymhatter_username }}"
  when: not tool_check.stat.exists
```

## Architecture Handling

Use `ansible_architecture` for conditional logic:

```yaml
# Different binary names per arch
url: "tool-{{ 'arm64' if ansible_architecture == 'aarch64' else 'amd64' }}"

# Compile from source on ARM64
- name: Install from source (ARM64)
  when: ansible_architecture == "aarch64"
```

## Version Pinning

Add to `ansible/group_vars/all/defaults.yml`:

```yaml
tool_version: "1.2.3"
```
