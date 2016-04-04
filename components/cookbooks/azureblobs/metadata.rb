name             'Azureblobs'
maintainer       'walmart'
maintainer_email 'kowsalya.palaniappan@walmart.com'
license          'All rights reserved'
description      'Installs/Configures azureblobs'
version          '0.1.0'
depends		      "azureblobs"

grouping 'default',
         :access => "global",
         :packages => [ 'base', 'service.storage', 'mgmt.cloud.service', 'cloud.service' ],
         :namespace => true

attribute 'tenant_id',
          :description => "Azure Tenant ID",
          :required => "required",
          :default => "Enter Tenant ID associated with Azure AD",
          :format => {
              :help => 'tenant id',
              :category => '1.Authentication',
              :order => 1
          }

attribute 'subscription',
          :description => "Subscription Id",
          :required => "required",
          :default => "",
          :format => {
              :help => 'subscription id in azure',
              :category => '1.Authentication',
              :order => 2
          }

attribute 'client_id',
          :description => "Client Id",
          :required => "required",
          :default => "",
          :format => {
              :help => 'client id',
              :category => '1.Authentication',
              :order => 3
          }

attribute 'client_secret',
          :description => "Client Secret",
          :encrypted => true,
          :required => "required",
          :default => "",
          :format => {
              :help => 'client secret',
              :category => '1.Authentication',
              :order => 4
          }

attribute 'region',
          :description => "Location",
          :default => "South Central US",
          :format => {
              :help => 'Use the location string',
              :category => '2.Config',
              :order => 5,
              :form => { 'field' => 'select', 'options_for_select' => [
                  ['Central US','centralus'],
                  ['East US','eastus'],
                  ['East US 2','eastus2'],
                  ['North Central US','northcentralus'],
                  ['South Central US','southcentralus'],
                  ['West US','westus']
              ]
              }
          }


recipe "check_subscription_status", "Check Subscription Status"