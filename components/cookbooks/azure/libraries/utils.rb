module Utils

  # this class should contain methods to manipulate different component names used within different azure recipes..
  class NameUtils
    def get_component_name(type, ciId)
      ciId = ciId.to_s
      if type == "nic"
        return "nic-"+ciId
      elsif type == "publicip"
        return "publicip-"+ciId
      elsif type == "privateip"
        return "nicprivateip-"+ciId
      elsif type == "lb_publicip"
        return "lb-publicip-"+ciId
      elsif type == "ag_publicip"
        return "ag_publicip-"+ciId
      end
    end

    def get_dns_domain_label(platform_name, cloud_id, instance_id, subdomain)
      subdomain = subdomain.gsub(".", "-")
      return (platform_name+"-"+cloud_id+"-"+instance_id.to_s+"-"+subdomain).downcase
    end

  end
end
