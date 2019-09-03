
def create_ingress()
    apply_template_file(
          namespace: namespace,
          file: "spec/fixtures/external-dns-ingress.yaml.erb",
          binding: binding
    )
    wait_for(namespace, "ingress", "ingress-external-dns", 60)
)