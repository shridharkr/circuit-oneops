
solrcloud Cookbook
===================
This solr cookbook installs solr cloud and uploads the default config to zookeeper . It has the below features
 1. To deploy on the given data center and uploads the config to its zookeeper . 
 2. Create a collection . 
 3. Reload a collection . 
 4. Add a replica to the cluster for a given collection . 
 5. Upload the custom config to zookeeper .


Attributes
----------
SolrCloud :
1.solr_package_type
2.solr_version
3.solr_format
4.deploy_all_dcs
5.zk_host_fqdns
6.config_name
7.custom_config_url
8.custom_config_name


SolrCloud Action Items :
9.collection_name
10.num_shards
11.replication_factor
12.max_shards_per_node

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


