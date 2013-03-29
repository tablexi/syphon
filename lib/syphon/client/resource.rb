class Syphon::Client::Resource
  ACTIONS = [ :index, :show, :create, :update, :delete ].freeze

  ACTION_MAP = { index:  [:all, :first],
                 show:   [:find],
                 create: [:create],
                 update: [:update],
                 delete: [:destroy] }.freeze

  def initialize(agent, name, uri, opts = {})
    @agent = agent
    @name = name
    @uri = uri

    allowed_actions = ACTIONS && (opts[:only] || ACTIONS) - (opts[:except] || [])
    disallowed_actions = ACTIONS - allowed_actions

    add_actions(allowed_actions) { |a, m| send("_#{m}") }
    add_actions(disallowed_actions) { |a, m| raise_unsupported(a) }
  end

private

  # index
  #
  def _all(conditions = {})
    @agent.get(collection_uri, body: { conditions: conditions }.to_json)
  end

  def _first(conditions = {})
    all(conditions.merge(limit: 1)).first
  end

  # show
  #
  def _find(id)
    @agent.get(resource_uri(id))
  end

  # create
  #
  def _create(attributes = {})
    @agent.post(collection_uri, body: { attributes: attributes }.to_json)
  end

  # update
  #
  def _update(id, attributes = {})
    @agent.put(resource_uri(id), body: { attributes: attributes }.to_json)
  end

  # destroy
  #
  def _destroy(id)
    @agent.delete(resource_uri(id))
  end

  # helpers
  
  def raise_unsupported(action)
    raise "#{action.upcase} is unsupported for this resource"
  end

  def add_actions(actions)
    actions.each do |action|
      methods = ACTION_MAP[action]
      methods.each do |method|
        self.define_singleton_method(method) do
          yield action, method
        end
      end
    end
  end

  def collection_uri
    @uri
  end

  def resource_uri(id)
    "#{@uri}/#{id}"
  end

end
