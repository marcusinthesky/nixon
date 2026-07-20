# Opt-in infrastructure, cloud, and Kubernetes tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    google-cloud-sdk
    dvc-with-remotes

    kubectl
    minikube
    kubernetes-helm
    k9s
    kube-linter
    kustomize
    skaffold
    ctlptl
    docker-compose

    terraform
    opentofu
    terragrunt
    tflint
    terraform-ls
  ];
}
