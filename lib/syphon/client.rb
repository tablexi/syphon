require 'syphon/common/resource'
require 'syphon/common/resource_dsl'

class Syphon::Client
  autoload :Resource, 'syphon/client/resource'

  def api(config = nil, &definition)
    @resources = Syphon::ResourceDSL[config,
      { resource_class: Syphon::Client::Resource,
        commands: [:namespace, :resources, :resource, :collection] },
      &definition]

    add_resource_actions
  end

  alias_method :discover, :api

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
