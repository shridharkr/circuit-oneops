# SolrCloud Cookbook


SolrCloud Pack is a platform service that makes it easy to set up, manage, deploy, operate and scale solrcloud as a search solution for your we application in walmart private and public clouds. You can set up and configure your Solrcloud cluster in minutes from the ONEOPS and enables you to monitor and resize your cluster up or down. As your volume of data and traffic fluctuates, the pack automatically scales to meet the rapidly scaling search requirements. The pack monitors the solution to ensure that a) it has sufficient resources, and that b) it isn’t consuming too many resources. With the Walmart SolrCloud platform you don’t have to manage multiple pieces of software, manually configure, design a replication and high-availability strategy, provision hardware, scale your search engine, or recover failed nodes. The environment is automatically kept up-to-date and provide maintenance and support of the solution and reduces the the time to configure and implement the SolrCloud search solution.


Apache Solrcloud is an open source enterprise search platform, written in Java. SolrCloud Pack installs any version of the apache solrcloud ( 4.x.x, 5.x.x, 6.0.0 ). The solrcloud pack installs solr as a war in a tomcat web container for 4.x.x versions and as a standalone server for 5.x.x , 6.x.x versions etc.

The objective of this document is to guide the solrcloud pack installation with Internal/External/Embedded zookeeper cluster mode based on the user selection and uploads the default config to the zookeeper and gets started. The assumption is that the zookeeper is already installed and ready if the user choose the External Ensemble. The zookeeper and the solrcloud gets install at once for Internal Ensemble (same assembly) option.

Please note that the actions in the operation phase are not used for the solrcloud with embedded zookeeper mode. It is a local installation with a single zookeeper instance running locally. We need to do all actions through command line or solrcloud REST API's.




## Supported features in the solrcloud pack


### Action Phase
```
* Create collection.
* Reload collection.
* Modify collection
* Add node as replica to the given shard of a given collection.
* Start/Stop/Status/Restart solr service.
* Upload the custom config to zookeeper.
* Update the clusterstate to the zookeeper --- Remove the dead cores or dead replicas and updates the cluster state to the zookeeper.
```


### Deployment Phase ( Design/Transition )
```
* Upload the custom config to zookeeper.
* Allows to set the GC/JVM parameters and to update the zookeeper cluster configuration ( FQDN connection string ).
* Provided an option in the pack to add the replaced node to the solrcloud cluster for 4.x.x versions.
```



# Installation Steps

* Create an Assembly
-- GoTo https://oneops.prod.walmart.com and create assembly .
#### Design Phase
 * Add a "New Platform".
 * Choose "SolrCloud" pack in "walmartLabs" pack source. Save and Commit the design.
 * Click on the "solrcloud" component .
 * Click on the "user-app" Component and add the developers ssh keys.

   ###### Note
   If you want to deploy solr-4.x.x version then update the required parameters of the"tomcat" component else ignore the tomcat component configuration.
 
   ##### Tomcat Component Parameters
   * Java_Options : Add/Update the JVM parameters.
   * Access Log Parameters : Add/Update the access log parameters in this section . You can add the values to enable the access logs and delete the values to disable the access logging.

   ##### Solrcloud component parameters
     * Solr Base url : Use the given default value.
     * Solr Binary Distribution package type : Select "solr" always.
     * Solr Binary Distribution format : select "tgz" format always.
     * Solr Binary Distribution version : Choose the required version.
     * default configname  : Update if required.
     * nexus url of custom solr config - Give the nexus path of config with .jar extension.
     * custom configname - Give the custom config name for the custom config jar.

     ###### Note
      * If you choose any 4.x.x version then it shows an option."Add all of the replaced nodes to the old collection".
      * If you choose any 5.x.x/6.x.x version then it asks for a set of additional parameters in the section "SolrCloud stand alone server parameters" to customize the installation/data directory paths.

     ##### SolrCloud stand alone server parameters section
      * installation_dir_path
      * data_dir_path
      * port_no
      * gc_tune_params
      * gc_log_params
      * solr_opts_params
      * solr_max_heap
      * solr_min_heap

     ##### Zookeeper section
      There are 3 options : 
      * External Ensemble - Need to provide the external zookeeper fqdns string.
      * Embedded zookeeper
        * Need to provide few parameters. [ 1. no of instances - to launch on a single node and 2. port no list ] - to run on a node.
        * Solrcloud detects the zookeeper which is in the same assembly and constructs the fqdn connection string and gets installed with the zookeeper in the same assembly.
      * Internal Ensemble (same assembly) - Need to provide few parameters. [ 1.platform_name ] of the zookeeper design to construct the fqdn string locally.

 * Commit the design.

#### Transition Phase
 * Create an environment and pull the design into transition phase .
 * Choose  "redundant" mode and update the scaling values .
 ##### Note
  * We can also update the components in the transition phase and then needs to be locked .
 
 ##### Changes to "user-app" Component
  * We can add more ssh keys if required and lock this component to avoid overriding the ssh keys from the design phase when you pull the latest design .

 ##### Changes to "solrcloud" Component
  * We can update the values provided in the design phase for each environment in the transition phase if required.

 ##### Changes to "tomcat" Component
  * Only if you install solr-4.x.x version.
  * Deploy the changes in the environment. Go to Operations phase and Verify the installation.

 ##### Note:
  * If you choose higher version (5.x.x/6.x.x) then the solrcloud component stops the tomcat service and creates a service with name solr<major_version_no>.


#### Operation Phase

##### SolrCloud component Action Items
* createCollection - Creates the collection.
  * Parameters
    * collectionname - We can create/reload collection and add replica to collection .
    * numShards - Give the no of shards required to create a collection .
    * replicationFactor - Give the replcationFactor to create no of replicas in a collection .
    * maxShardsPerNode - Give the max shards per node required to create a collection .
* addreplica - Adds replica to the given shard and collection .
  * Parameters:
    * collectionname - Collection name
    * shardname - shard name
* reloadcollection - Reloads the collection.
  * Parameters:
    * collectionname - Reloads collection.
* deletecollection - Delete a collection.
  * Parameters:
    * collectionname - Reloads collection.
* modifycollection - Modifies a collection.
* updateclusterstate - Remove the dead cores or dead replicas and updates the cluster state to the zookeeper.
* uploadsolrconfig - Upload the custom config to zookeeper.
  * Parameters:
    * CustomConfigJar - Custom config jar nexus path.
    * CustomConfigName - Custom config name.
* start - Start the solrcloud
* stop - Stop the solrcloud
* restart - Restart the solrcloud
* status - Print the status of solrcloud in the log.



# Update the Installation
  * Touch any component to update or re-install that component .
  * Touch the "tomcat" and "solrcloud" computes to update the solr-4.x.x version  installation. (or) Touch the solrcloud component to update the solr-5.x.x/solr-6.x.x version installation.
  * Follow the below steps to change the solr version and install new major version of solrcloud
    * Go to Operations phase and Stop the solr
    * Go to Transition phase and Update the solr version and other required attributes in the solrcloud component.
    * Commit and deploy the solrcloud with new version.
    ##### Note
        * This is to deploy another major version on the same VM and test the functionality of your use cases/sceanrios and it doesn't upgrade the installation of solr version to higher version.
  * To reinstall the ssh keys , Touch and update the "user-app" component .
  * To add the ssh keys , Go to Transition phase and add the ssh keys to the "user-app" component and deploy the changes.

    ##### solr-4.x.x version
    * To update the zookeeper connection string -  Update the "zookeeper fqdn" string in the solrcloud component and do touch and deploy both the "tomcat" and "solrcloud" components.
    * Directory structure of pack installation
    ```      
    /{use-app}/solr-config
    /{use-app}/solr-config/default
    /{use-app}/solr-config/prod
    /{use-app}/solr-war-lib
    /{use-app}/tomcat7
    /{use-app}/tomcat7/logs
    /{use-app}/solr-cores/solr.xml
    ```

    ##### solr-5.x.x/6.x.x version
    * To update the zookeeper connection string -  Update the "zookeeper fqdn" string in the solrcloud component and do touch and deploy the "solrcloud" component.
    * Directory structure of pack installation
    ```
    /{installation_dir_path}/solr-config{solr_major_version}
    /{installation_dir_path}/solr-config{solr_major_version}/default
    /{installation_dir_path}/solr-config{solr_major_version}/prod
    /{installation_dir_path}/solr-war-lib{solr_major_version}
    /{installation_dir_path}/solr{solr_major_version}
    /{installation_dir_path}/solrdata{solr_major_version}
    /{installation_dir_path}/solrdata{solr_major_version}/data
    /{installation_dir_path}/solrdata{solr_major_version}/data/solr.xml
    /{installation_dir_path}/solrdata{solr_major_version}/logs
    ```

# Replace the compute
  * Go to Operation phase of the platform and select the compute - > Click on the compute and Go to configuration tab - > Select replace option to replace the compute .
  * Go to Transition phase and Touch any component to re-deploy the pack and install on the replaced computes .




