class Syphon::Api::ModelProxy

  class << self

    attr_reader :model

    def new_class(*args)
      Class.new(self).init(*args)
    end

    def init(resource)
      @model = resource.model_class
      @pkey  = resource.primary_key
      @decorator = Syphon::Api::ModelDecorator.new_class(resource)
      self
    end

    # TODO: limit query to included columns
    #
    def all(conditions = [])
      conditions ||= []

      # query conditions must come first
      conditions.sort_by! { |v| v.is_a?(Hash) ? 0 : 1 }

      results = conditions.reduce(@model.all) do |query, cond|
        case cond
        when Hash
          cond.reduce(query) { |query, (cond, val)| query.send(cond, val) }
        else
          query.send(cond)
        end
      end

      results.map { |o| wrap o }
    end

    def find(id)
      wrap find_by_pkey(id)
    end

    def create(attributes = {})
      obj = @model.create(attributes)
      obj.valid? ? find(obj.send(@pkey)) : obj
    end

    def update(id, attributes = {})
      find_by_pkey(id).update_attributes(attributes)
    end

    def destroy(id)
      find_by_pkey(id).destroy
    end

    def wrap(object)
      object && @decorator.wrap(object)
    end

    #TODO: why is this class a singleton? refactor it to a regular class and
    # use new here
    #
    def with_model(model)
      new_proxy = self.clone
      new_proxy.instance_variable_set('@model', model)
      new_proxy
    end

  private

    def find_by_pkey(id)
      id ? @model.send("find_by_#{@pkey}", id) : @model.first
    end

  end
end
