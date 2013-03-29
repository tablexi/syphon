class Syphon::Api
  private_class_method :new # enforce singleton

  class << self

    attr_accessor :resources

    def api(&definition)
      @resources = DSLContext[definition]
    end

    def draw_routes!(application)
      return if @resources.empty?
      @resources.each do |resource|
        resource.build_controller
        resource.draw_route(application)
      end
    end

  end
end
