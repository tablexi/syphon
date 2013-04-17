class Syphon::Api::ModelProxy

    class_attribute :model, :pkey, :decorator

    def self.new_class(*args)
      Class.new(self).init(*args)
    end

    def self.init(resource)
      self.model = resource.model_class
      self.pkey  = resource.primary_key
      self.decorator = Syphon::Api::ModelDecorator.new_class(resource)
      self
    end

    def initialize(model = nil)
      self.model = model || self.model
    end

    # TODO: limit query to included columns
    #
    def all(conditions = [])
      conditions ||= []

      # query conditions must come first
      conditions.sort_by! { |v| v.is_a?(Hash) ? 0 : 1 }

      results = conditions.reduce(model.all) do |query, cond|
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
      obj = model.create(attributes)
      obj.valid? ? find(obj.send(pkey)) : obj
    end

    def update(id, attributes = {})
      obj = find_by_pkey(id)
      obj.update_attributes(attributes)
      obj
    end

    def destroy(id)
      obj = find_by_pkey(id)
      obj.destroy
      obj
    end

    def wrap(object)
      object && decorator.wrap(object)
    end

  private

    def find_by_pkey(id)
      id ? model.send("find_by_#{pkey}", id) : model.first
    end

end
