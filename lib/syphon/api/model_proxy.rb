class Syphon::Api::ModelProxy

  class << self

    def init(resource)
      @model = resource.model_klass
      @decorator = Class.new(Syphon::Api::ModelDecorator).init(resource)
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
      wrap @model.find_by_id(id)
    end

    def create(attributes = {})
      obj = @model.create(attributes)
      obj.valid? ? find(obj.id) : obj
    end

    def update(id, attributes = {})
      @model.update(id, attributes)
    end

    def destroy(id)
      @model.destroy(id)
    end

    def wrap(object)
      object && @decorator.new(object).to_h
    end

  end
end
