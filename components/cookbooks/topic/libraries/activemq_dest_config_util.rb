module Topic
  module Activemq_dest_config_util
    DEFAULT_DESTINATION_POLICIES = '
       <destinationPolicy>
          <policyMap>
              <policyEntries>
                 <policyEntry queue=">" >
                    <deadLetterStrategy>
                        <sharedDeadLetterStrategy processExpired="false"/>
                    </deadLetterStrategy>
                </policyEntry>
                <policyEntry topic=">" >
                    <pendingMessageLimitStrategy>
                        <constantPendingMessageLimitStrategy limit="1000"/>
                   </pendingMessageLimitStrategy>
                </policyEntry>
              </policyEntries>
          </policyMap>
       </destinationPolicy>
    '

    require 'nokogiri'

    def self.deleteDestPolicy(config_xml, dest_type, dest_name)
       origxml0 = IO.read(config_xml)
       origxml = origxml0.sub('<broker xmlns="http://activemq.apache.org/schema/core" ', "<broker ")
       origdoc = Nokogiri::XML(origxml)
       dest_policies = origdoc.at('destinationPolicy')
       if ( dest_policies == nil )
          Chef::Log.info("no policy found; no action taken for deleting #{dest_type} #{dest_name} destination policy")
          return
       end

       if ( 'T' == dest_type )
           policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@topic="'+"#{dest_name}" +'"]'
       elsif ('Q' == dest_type )
           policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@queue="'+"#{dest_name}" +'"]'
       else
           raise "destination type has to be either 'topic' or 'queue'"
       end
       dest_policy = origdoc.at(policypath)
       if (dest_policy == nil)
          Chef::Log.info("no policy found; no action taken for deleting #{dest_type} #{dest_name} destination policy")
          return
       end

       #delete this policy
       Chef::Log.info("#{dest_type} #{dest_name} destination policy deleted: " + dest_policy.to_html.gsub(/\&gt;/, '>'))
       dest_policy.replace('')
       resultdoc = origdoc.to_html.sub("<broker ", '<broker xmlns="http://activemq.apache.org/schema/core" ')
       File.open(config_xml,"w") { |f| f << resultdoc.gsub(/\&gt;/, '>') }
       #puts origdoc.to_xhtml(indent:3).gsub(/\&gt;/, '>')
    end

    def self.processDestPolicy(config_xml, dest_type, dest_name, policies)
        origxml0 = IO.read(config_xml)
        origxml = origxml0.sub('<broker xmlns="http://activemq.apache.org/schema/core" ', "<broker ")
        origdoc = Nokogiri::XML(origxml)
        dest_policies = origdoc.at('destinationPolicy')

        if (!policies.nil?)
            policies.strip!
        end
        policydoc = (policies.nil? || policies.empty?) ? nil : Nokogiri::XML(policies)

        #make sure dest_policies is not nil or quit
        if ( dest_policies == nil )
           if (policies.nil?)
              Chef::Log.info("activemq.xml has no destination policies, and #{dest_type} #{dest_name} has no policy, nothing to do")
              return
           end

           # add default destinationPolicy stanza
           brokerdoc = origdoc.at('broker')
           brokerdoc.first_element_child.before(DEFAULT_DESTINATION_POLICIES)
           dest_policies = origdoc.at('destinationPolicy')
        end

        # puts dest_policies.to_html
        if ( 'T' == dest_type )
            policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@topic="'+"#{dest_name}" +'"]'
            policypath2 = 'policyEntry[@topic="'+"#{dest_name}" +'"]'
        elsif ('Q' == dest_type )
            policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@queue="'+"#{dest_name}" +'"]'
            policypath2 = 'policyEntry[@queue="'+"#{dest_name}" +'"]'
        else
            raise "destination type has to be either 'topic' or 'queue'"
        end

        dest_policy = origdoc.at(policypath)
        if (policydoc != nil)
            policydoc2 = policydoc.at(policypath2)
        end

        if (dest_policy == nil)
            Chef::Log.info("no destination policy found for #{dest_type} #{dest_name} in activemq.xml")
            if (!policydoc2.nil?)
               # add policyEntry for destination
               insert_point = dest_policies.at('policyMap/policyEntries')
               insert_point.first_element_child.before(policydoc2)
            else
               Chef::Log.info("#{dest_type} #{dest_name} has no policy from OneOps GUI, nothing to do")
               return
            end
        else
            # puts dest_policy.to_html
            # found existing entry, process replacement
            if (policydoc2.nil?)
               #GUI has input, but it is an invalid destination policy for the queue/topic
               if (!policies.nil?)
                 raise "#{dest_type} #{dest_name} destinationPolicy: #{policies}. It may have wrong destination name or other problems"
               end
               # delete destination policy entry because it is empty or nil from GUI
               Chef::Log.info("new policyEntry for #{dest_type} #{dest_name} is empty; deleting existing entry")
               dest_policy.replace('')
            else
               # replace/update destination policy entry
               Chef::Log.info("replace/update policyEntry for #{dest_type} #{dest_name}")
               dest_policy.replace(policydoc2)
            end
        end

        #puts origdoc.to_html
        # overwrite original xml config file
        resultdoc = origdoc.to_html.sub("<broker ", '<broker xmlns="http://activemq.apache.org/schema/core" ')
        File.open(config_xml,"w") { |f| f << resultdoc.gsub(/\&gt;/, '>') }
        #puts origdoc.to_xhtml(indent:3).gsub(/\&gt;/, '>')
    end
  end
end
