require "ostruct"
require_relative "ext_kernel"

require_relative "iis_pool_root"
require_relative "iis_pool_cpu"
require_relative "iis_pool_process_model"
require_relative "iis_pool_recycling"
require_relative "iis_pool_periodic_restart"
require_relative "iis_pool_failure"

module OO
  class IIS
    class AppPoolDefaults

      silence_warnings do
        SECTION = "system.applicationHost/applicationPools"
        APP_POOL_DEFAULTS = "applicationPoolDefaults"
      end

      def initialize(web_administration)
        @web_administration = web_administration
        reload
      end

      def reload
        @web_administration.readable_section_for("system.applicationHost/applicationPools") do |section|
          @entity = section.ChildElements.Item(APP_POOL_DEFAULTS)
          @cpu = @entity.ChildElements.Item("cpu")
          @process_model = @entity.ChildElements.Item("processModel")
          @recycling = @entity.ChildElements.Item("recycling")
          @periodic_restart = @recycling.ChildElements.Item("periodicRestart")
          @failure = @entity.ChildElements.Item("failure")
        end
      end

      def configure(attributes)
        @web_administration.perform { configure_attributes_for_app_pool_defaults(attributes) }
      end

      def root
        Root.new(@entity).attributes
      end

      def cpu
        CPU.new(@cpu).attributes
      end

      def process_model
        ProcessModel.new(@process_model).attributes
      end

      def recycling
        Recycling.new(@recycling).attributes
      end

      def periodic_restart
        PeriodicRestart.new(@periodic_restart).attributes
      end

      def failure
        Failure.new(@failure).attributes
      end

      protected

      def configure_attributes_for_app_pool_defaults(attributes)
        @web_administration.writable_section_for(SECTION) do |section|
          pool_defaults = section.ChildElements.Item(APP_POOL_DEFAULTS)
          configure_attributes(pool_defaults, attributes)
        end
        reload
      end

      private

      def configure_attributes(pool_defaults, attributes)
        default_attributes = attributes["default"] || {}
        cpu_attributes = attributes["cpu"] || {}
        process_model_attributes = attributes["process_model"] || {}
        recycling_attributes = attributes["recycling"] || {}
        periodic_restart_attributes = attributes["periodic_restart"] || {}
        failure_attributes = attributes["failure"] || {}

        cpu = pool_defaults.ChildElements.Item("cpu")
        process_model = pool_defaults.ChildElements.Item("processModel")
        recycling = pool_defaults.ChildElements.Item("recycling")
        periodic_restart = recycling.ChildElements.Item("periodicRestart")
        failure = pool_defaults.ChildElements.Item("failure")

        Root.new(pool_defaults).assign_attributes(default_attributes)
        CPU.new(cpu).assign_attributes(cpu_attributes)
        ProcessModel.new(process_model).assign_attributes(process_model_attributes)
        Recycling.new(recycling).assign_attributes(recycling_attributes)
        PeriodicRestart.new(periodic_restart).assign_attributes(periodic_restart_attributes)
        Failure.new(failure).assign_attributes(failure_attributes)
      end
    end
  end
end
