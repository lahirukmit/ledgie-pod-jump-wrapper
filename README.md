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
- It is **menu-only by design**. There are no flags or arguments, so a stale value from shell history or a copied command can never skip a menu and send you to the wrong cluster. Before it execs, it shows the cluster, namespace, pod, and container and waits for you to confirm.

## Files

- `podjump` - main command
- `install.sh` - installer
- `uninstall.sh` - removes only `podjump` from `~/.local/bin`

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

The installer copies `podjump` to `~/.local/bin` and makes sure that directory is on your `PATH` in `~/.zshrc`.

After install, either:

- open a new terminal session, or
- run:

```bash
source ~/.zshrc
```

Fallback if shell is not refreshed yet:

```bash
~/.local/bin/podjump
```

## Usage

```bash
podjump
```

That's the only command. It takes no arguments.

1. **Cluster:** pick a kube context.
2. **Namespace:** pick a namespace in that cluster.
3. **Instance:** pick a ledgie instance (`ledgie`, `ledgie-fcm`, `ledgie-paper`, ...). Only instances with `app.kubernetes.io/component=api-server` pods are listed.
4. **Pod:** pick a running pod. This step is skipped when there's only one.
5. **Container:** pick a container. This step is skipped when there's only one.
6. **Confirm:** check the summary, then type `y` to exec, `b` to go back, or anything else to quit.

You land in `bash`, or in `sh` if the image has no `bash`.

Keys:

- arrow keys or type to filter, then `Enter` to select
- pick `<< back: ... >>` to return to the previous step
- `Esc` or `Ctrl+C` to quit without executing anything

## Uninstall

```bash
./uninstall.sh
```

`uninstall.sh` removes only `~/.local/bin/podjump`.

It does **not** remove or modify:

- `bash`
- `kubectl`
- `fzf`
- kube access/contexts in your kubeconfig
- RBAC permissions
- optional tools: `kubectx`, `kubens`
