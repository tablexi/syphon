require 'json'
require 'ostruct'
require 'syphon/dsl_context'

class Syphon::Client
  autoload :Resource, 'syphon/client/resource'

  def api(&definition)
    @resources = Syphon::DSLContext[definition, 
      resource_class: Syphon::Client::Resource,
      commands: [:namespace, :resource, :resources, :collections]]
    @resources.each { |n, r| r.api = self } # hack, figure out a better way to backreference

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
