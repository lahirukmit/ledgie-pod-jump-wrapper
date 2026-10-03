# podjump

Pick a cluster, namespace, and ledgie pod from a menu, then exec into it, without touching your terminal's kube context.

## Why this exists

Every day we exec into different ledgie pods (`ledgie`, `ledgie-fcm`, `ledgie-paper`, `ledgie-crypto`, and others) across clusters to grant access to users. Doing that by hand means:

- **Looking up pod names every time.** Pod names change with every rollout, and `kubectl exec deploy/ledgie` can land on the wrong pod because the Deployment selector also matches other ledgie workloads.
- **Switching cluster and namespace with `kubectx` / `kubens`.** That takes time, and it's easy to type a wrong value.
- **Running later commands against the wrong cluster.** If you forget to switch back, your next `kubectl` command runs against whatever context you left active, which could be production.

`podjump` fixes all three:

- You pick the context, namespace, instance, pod, and container from arrow-key menus (`fzf`), so there's nothing to type and nothing to mistype.
- It finds pods by label (`app.kubernetes.io/component=api-server` plus `app.kubernetes.io/instance=<instance>`), so you always land on the pod for the instance you chose.
- It passes `--context` and `-n` explicitly on every `kubectl` call and **never changes your active kube context or namespace**. When you exit the pod, your terminal is still pointing where it was before.

## Files

- `podjump` - main command
- `install.sh` - installer

## Prerequisites

- `bash`
- `kubectl`
- `fzf`
- valid kube access and contexts in your kubeconfig
- RBAC permissions to list pods/namespaces and exec into pods

Optional:

- `kubectx`
- `kubens`

## Install

```bash
git clone https://github.com/lahirukmit/ledgie-pod-jump-wrapper.git
cd ledgie-pod-jump-wrapper
./install.sh
```

The installer copies `podjump` to `~/.local/bin` and makes sure that directory is on your `PATH` in `~/.zshrc`. If you installed the older `ledgie-access` / `access` version, it removes those too.

After install, either:

- open a new terminal session, or
- run:

```bash
source ~/.zshrc
```

## Usage

Show help:

```bash
podjump --help
```

Interactive flow:

```bash
podjump
```

Target a specific instance:

```bash
podjump ledgie
podjump ledgie-fcm
```

Run one command instead of opening shell:

```bash
podjump ledgie hostname
```

Override namespace/context:

```bash
podjump -n default ledgie
```

## Notes

- default component selector is `app.kubernetes.io/component=api-server`
- if multiple pods/containers match, a picker menu is shown
- in a picker, choose `<< back: ... >>` to return to the previous step
- if container image does not include `bash`, run:

```bash
podjump ledgie sh
```
