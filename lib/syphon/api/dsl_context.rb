class Syphon::Api::DSLContext

  CONTEXT_VARS = :ctx_type, :ctx_namespace, :ctx_super_controller, :ctx_resource

  class Context < Struct.new(:parent, *CONTEXT_VARS)
    # emulate lexical scoping
    CONTEXT_VARS.each do |reader|
      send(:define_method, reader) do
        super() || (parent && parent.send(reader))
      end
    end
  end

  CONTEXT_VARS.each do |var|
    send(:define_method, var) { @context.send(var) }
    send(:define_method, "#{var}=") { |val| @context.send("#{var}=", val) }
  end

  def initialize
    @resources = []
    @context = Context.new(nil, :root, '')
    @context_stack = []
  end

  def namespace(name, &block)
    new_context :namespace, block do
      self.ctx_namespace += "/#{name}"
    end
  end

  def resource(name, opts = {}, &block)
    new_context :resource, block do
      self.ctx_resource = \
        Syphon::Api::Resource.new(name, ctx_namespace, ctx_super_controller, opts)
      @resources << ctx_resource
    end
  end

  # Not wrapped in context block since controller command can be called anywhere
  # legally
  #
  def controller(klass)
    case ctx_type
    when :root, :namespace
      self.ctx_super_controller = klass
    when :resource
      ctx_resource.controller = klass
    end
  end

  def model(klass)
    check_context_nesting(:inner)
    ctx_resource.model = klass
  end

  [:fields, :resources, :collections].each do |method|
    send(:define_method, method) do |*val|
      check_context_nesting(:inner)
      ctx_resource.send("#{method}=", val)
    end
  end

private

  def new_context(type, proc = nil)
    create_new_context(type)

    # run context initializer
    yield

    # execute user provided block within context
    self.instance_eval(&proc) if proc

    restore_old_context
  end

  def create_new_context(type)
    check_context_nesting(type)
    new_context = Context.new(@context, type)
    @context_stack.push(@context)
    @context = new_context
  end

  def restore_old_context
    @context = @context_stack.pop
  end

  def check_context_nesting(new_context_type)
    error = \
      case new_context_type
      when :namespace
        ctx_type != :root && ctx_type != :namespace
      when :resource
        ctx_type != :root && ctx_type != :namespace 
      when :inner
        ctx_type != :resource
      else false
      end

    raise "You cannot call '#{new_context}' inside a '#{context}' block" if error
  end


  def self.[](definition)
    dsl = self.new
    dsl.instance_eval(&definition)
    dsl.instance_variable_get('@resources')
  end

end
