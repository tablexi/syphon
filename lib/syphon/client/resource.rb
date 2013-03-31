class Syphon::Client::Resource < Syphon::Resource

  ACTION_MAP = { index:  [:all, :first],
                 show:   [:find],
                 create: [:create],
                 update: [:update],
                 destroy: [:destroy] }.freeze

  attr_accessor :agent

  def initialize(name, resource_set, context, opts = {})
    super
    expose_allowed_actions
  end

private

  # index
  #
  def _all(*conditions)
    agent.get(collection_uri, query: { conditions: conditions })
  end

  def _first(*conditions)
    _all(*(conditions << {limit: 1})).first
  end

  # show
  #
  def _find(id)
    agent.get(resource_uri(id))
  end

  # create
  #
  def _create(attributes = {})
    agent.post(collection_uri, body: { attributes: attributes }.to_json)
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
      wrap_response(send("_#{m}", *args))
    end

    add_actions(@disallowed_actions) do |a, m, args| 
      raise_unsupported(a)
    end
  end

  def add_actions(actions)
    actions.each do |action|
      methods = ACTION_MAP[action]
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

  # FIXME: needs work
  #
  def wrap_response(response)
    @resources.each do |resource|
      params = response[resource.to_s]
      response[resource] = lambda { @resource_set[pluralize(resource)].find(params) }
    end

    @collections.each do |collection|
      params = response[collection.to_s]
      response[collection] = lambda { @resource_set[collection.to_sym].all(params) }
    end

    wrapper = OpenStruct.new(response)

    (@resources + @collections).each do |reader|
      old_method = wrapper.method(reader)
      wrapper.define_singleton_method(reader) do
        old_method.call.call
      end
    end

    wrapper
  end

end
