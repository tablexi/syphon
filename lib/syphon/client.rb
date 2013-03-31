require 'syphon/common/resource'
require 'syphon/common/resource_dsl'

class Syphon::Client
  autoload :Resource, 'syphon/client/resource'

  def api(&definition)
    @resources = Syphon::ResourceDSL[definition, 
      resource_class: Syphon::Client::Resource,
      commands: [:namespace, :resources, :resource, :collection]]

    add_resource_actions
  end

  # TODO: move to DSL class and clean up
  #
  def configure_for_syphon_service(config)
    @resources = {}
    config.each do |rconf|
      rconf = OpenStruct.new(rconf)
      opts = { only: rconf.allowed_actions.map {|a| a.to_sym} }
      rsrc = Syphon::Client::Resource.new(rconf.name, @resources, rconf, opts)
      rsrc.resources = rconf.resources
      rsrc.collections = rconf.collections
      @resources[rconf.name] = rsrc
    end

    @resources.each { |n,r| r.finalize! }
    add_resource_actions
  end

private

  def add_resource_actions
    @resources.each do |name, resource|
      resource.agent = agent
      define_singleton_method(resource.name) do
        return resource
      end
    end
  end

end
