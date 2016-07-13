name "kubernetes"
description "Kubernetes"
auth "kubernetessecretkey"
  
service "kubernetes",
  :cookbook => 'kubernetes',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'kubernetes' }
