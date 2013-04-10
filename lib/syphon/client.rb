class Syphon::Client
  autoload :Resource, 'syphon/client/resource'

  def api(config = nil, &definition)
    @resources = Syphon::ResourceDSL.parse(config,
      { resource_class: Syphon::Client::Resource },
      &definition)

    add_resource_actions
  end

  alias_method :discover, :api

  def resource_names
    @resources.map { |n, r| n }
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
