module Syphon::Client::RouterDSL
  def routes_for(agent, &block)
    DClient::Router.route!(self, agent, block)
  end
end

class Syphon::Router
  def self.route!(client, agent, routes)
    self.new.route!(client, agent, routes)
  end

  def initialize
    @route_uri = ''
  end

  def route!(client, agent, routes)
    @client = client
    @agent = agent
    @resources = client.resources
    self.instance_eval(&routes)
  end

private

  def namespace(name, &block)
    @route_uri += "/#{name}"
    instance_eval(&block)
  end

  def resource(name, opts = {})
    @resources[name] = Syphon::Resource.new(@agent, name, "#{@route_uri}/#{name}", opts)
    @client.define_singleton_method(name) do
      return @resources[name]
    end
  end
end
