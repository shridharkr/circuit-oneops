
def get_attribute_value(attr_name)
	node.workorder.rfcCi.ciBaseAttributes.has_key?(attr_name)? node.workorder.rfcCi.ciBaseAttributes[attr_name] : node.tomcat[attr_name]
end
