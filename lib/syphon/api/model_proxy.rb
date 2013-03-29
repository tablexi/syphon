class Syphon::Api::ModelProxy
  class_attribute :model

  class << self

    def all(finders = {})
      finders = finders || {}
      finders.reduce(model.select(@fields)) do |query, (finder, opts)|
        query.send(finder, opts)
      end
    end

    def find(id)
      model.find_by_id(id)
    end

    # FIXME: finish this
    #
    def create(attributes = {})
    end

    def update(id, attributes = {})
    end

    def destroy(id)
    end

  end
end
