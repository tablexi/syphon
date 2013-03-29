class Syphon::DSLContext

  CONTEXT_VARS = :type, :namespace, :super_controller, :resource

  class Context < Struct.new(:parent, *CONTEXT_VARS)
    # emulate lexical scoping
    CONTEXT_VARS.each do |reader|
      send(:define_method, reader) do
        super() || (parent && parent.send(reader))
      end
    end
  end

  attr_reader :context
  alias_method :ctx, :context

  def initialize(opts = {})
    @allowed_commands = opts[:commands]
    @resource_class = opts[:resource_class] || Syphon::Api::Resource 
    expose_allowed_commands

    @resources = []
    @context = Context.new(nil, :root, '')
    @context_stack = []
  end

  def namespace(name, &block)
    new_context :namespace, block do
      ctx.namespace += "/#{name}"
    end
  end

  def resource(name, opts = {}, &block)
    new_context :resource, block do
      ctx.resource = @resource_class.new(name, ctx, opts)
      @resources << ctx.resource
    end
  end

  # Not wrapped in context block since controller command can be called anywhere
  # legally
  #
  def controller(klass)
    case ctx.type
    when :root, :namespace
      ctx.super_controller = klass
    when :resource
      ctx.resource.controller = klass
    end
  end

  def model(klass)
    check_context_nesting(:inner)
    ctx.resource.model = klass
  end

  [:fields, :resources, :collections].each do |method|
    send(:define_method, method) do |*val|
      check_context_nesting(:inner)
      ctx.resource.send("#{method}=", val)
    end
  end

private

  def expose_allowed_commands
    return unless @allowed_commands
    private_commands = \
      public_methods(false) - @allowed_commands
    private_commands.each do |command|
      singleton_class.class_eval do
        private(command)
      end
    end
  end

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
        ctx.type != :root && ctx.type != :namespace
      when :resource
        ctx.type != :root && ctx.type != :namespace 
      when :inner
        ctx.type != :resource
      else false
      end

    raise "You cannot call '#{new_context}' inside a '#{context}' block" if error
  end


  def self.[](definition, opts = {})
    dsl = self.new(opts)
    dsl.instance_eval(&definition)
    dsl.instance_variable_get('@resources')
  end

end
