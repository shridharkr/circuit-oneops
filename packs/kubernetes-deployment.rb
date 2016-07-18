name          "kubernetes-deployment"
description   "Kubernetes Deployment/Application"
type          "Platform"
category      "Worker Application"

environment "single", {}
environment "redundant", {}
entrypoint "kubernetes-deployment"

resource "kubernetes-deployment",
	:cookbook => "oneops.1.kubernetes-deployment",
	:design	=> true,
	:requires => {"constraint" => "1..1", "services" => "kubernetes" }
