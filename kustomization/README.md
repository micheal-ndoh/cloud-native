# Kustomization

Base and overlays for environment-specific customization.

## Structure
- base/: common manifests
- overlays/dev/: development overlay

## Usage
```bash
kubectl apply -k overlays/dev/
```