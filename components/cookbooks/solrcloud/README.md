
solrcloud Cookbook
===================
This solr cookbook installs solr cloud by using external zookeeper or internal zookeeper based on the user choice and uploads the default config to the zookeeper.

The features are :
 1. Creates collection. 
 2. Reloads collection.
 3. Adds replica to the cluster for the given collection.
 4. Upload the custom config to embedded/external zookeeper.
 5. Replaces the replica to the collection when the compute gets replaced.




Attributes
----------
SolrCloud

1.solr_url
2.solr_package_type
3.solr_version
4.solr_format
5.config_name
6.custom_config_url
7.custom_config_name

Zookeeper

8.zk_select
9.zk_host_fqdns
10.num_local_instances
11.http_port_nos
12.ssl_port_nos
13.server_port_nos
14.ajp_port_nos



Usage
-----
#### solrcloud::add


Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github


License and Authors
-------------------




