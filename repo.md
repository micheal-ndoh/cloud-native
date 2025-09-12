# Repo push commands

## This repository (application source)

- Ensure remotes exist (idempotent):

```bash
git remote get-url gitea >/dev/null 2>&1 || git remote add gitea http://gitea.local/michealndoh/Cloud-native.git
git remote get-url github >/dev/null 2>&1 || git remote add github https://github.com/micheal-ndoh/cloud-native.git
```

- Push main to both:

```bash
git push gitea main
git push github main
```

## Infra repository (Cloud-native-infra) to Gitea

- Adjust the path if your infra repo is elsewhere:

```bash
INFRA_DIR="/home/micheal-ndoh/Desktop/Cloud-native-infra"

git -C "$INFRA_DIR" remote get-url origin >/dev/null 2>&1 || git -C "$INFRA_DIR" remote add origin http://gitea.local/michealndoh/Cloud-native-infra.git

git -C "$INFRA_DIR" push origin main
```