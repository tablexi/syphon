require 'json'
require 'ostruct'

class Syphon::Client::Resource < Syphon::Resource

  class ResponseWrapper < OpenStruct
    def inspect; @table.inspect end
    def to_s; @table.to_s end
  end

  METHOD_MAP = { index:  [:all, :first],
                 show:   [:find],
                 create: [:create],
                 update: [:update],
                 destroy: [:destroy] }.freeze

  attr_accessor :agent

  def initialize(name, resource_set, context, opts = {})
    super
    @response_wrapper = \
      self.class.const_set(resource_name.classify, Class.new(ResponseWrapper))

    expose_allowed_actions
  end

private

  # index
  #
  def _all(*conditions)
    wrap_responses agent.get(collection_uri, query: { conditions: conditions })
  end

  def _first(*conditions)
    _all(*(conditions << {limit: 1})).first
  end

  # show
  #
  def _find(id)
    wrap_response agent.get(resource_uri(id))
  end

  # create
  #
  def _create(attributes = {})
    wrap_response agent.post(collection_uri, body: { attributes: attributes }.to_json)
  end

  # update
  #
  def _update(id, attributes = {})
    agent.put(resource_uri(id), body: { attributes: attributes }.to_json) || true
  end

  # destroy
  #
  def _destroy(id)
    @agent.delete(resource_uri(id)) || true
  end

  # action helpers
  
  def expose_allowed_actions
    add_actions(@allowed_actions) do |a, m, args| 
      send("_#{m}", *args)
    end

    add_actions(@disallowed_actions) do |a, m, args| 
      raise_unsupported(a)
    end
  end

  def add_actions(actions)
    actions.each do |action|
      methods = METHOD_MAP[action]
      methods.each do |method|
        define_singleton_method(method) do |*args|
          yield(action, method, args)
        end
      end
    end
  end

  def raise_unsupported(action)
    raise "#{action.upcase} is unsupported for this resource"
  end

protected

  def wrap_response(response)
    return response if !response.is_a?(Hash) || response['exception']

    finders = []

    @resources.each do |resource|
      name = resource.resource_name
      relation_uri = response[name]

      response[name] = \
        if relation_uri
          finders << name
          lambda { resource.wrap_response agent.get(relation_uri) }
        else nil
        end
    end

    @collections.each do |resource|
      name = resource.collection_name
      query = response[name]

      response[name] = \
        unless query.empty?
          finders << name
          lambda { resource.wrap_responses agent.get(query) }
        else query
        end
    end

    wrapper = @response_wrapper.new(response)

    finders.each do |finder|
      old_method = wrapper.method(finder)
      wrapper.define_singleton_method(finder) do
        old_method.call.call
      end
    end

    wrapper
  end

  # FIXME: don't wrap in array for all
  def wrap_responses(response)
    return [response] if !response.is_a?(Array)

    response.map { |r| wrap_response r }
  end

end
