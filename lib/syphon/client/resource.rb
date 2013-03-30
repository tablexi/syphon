class Syphon::Client::Resource

  ACTIONS = [ :index, :show, :create, :update, :destroy ].freeze

  ACTION_MAP = { index:  [:all, :first],
                 show:   [:find],
                 create: [:create],
                 update: [:update],
                 destroy: [:destroy] }.freeze

  attr_accessor :api, :agent, :fields, :resources, :collections
  attr_reader   :name, :namespace, :allowed_actions, :disallowed_actions

  def initialize(name, context, opts = {})
    @name = name
    @namespace = context.namespace[1..-1] # remove leading slash
    @uri = "/#{@namespace}/#{@name}"
    @resources, @collections = [], []

    @allowed_actions = ACTIONS && (opts[:only] || ACTIONS) - (opts[:except] || [])
    @disallowed_actions = ACTIONS - allowed_actions

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
      response = send("_#{m}", *args)

      @resources.each do |resource|
        params = response[resource.to_s]
        response[resource] = lambda { @api.resources[pluralize(resource)].find(params) }
      end

      @collections.each do |collection|
        params = response[collection.to_s]
        response[collection] = lambda { @api.resources[collection.to_sym].all(params) }
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

  # uri helpers

  def collection_uri
    @uri
  end

  def resource_uri(id)
    "#{@uri}/#{id}"
  end

  # inflections

  def pluralize(name)
    "#{name}s".to_sym
  end

end
