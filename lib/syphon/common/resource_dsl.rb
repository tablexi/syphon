require 'ostruct'
require 'active_support/hash_with_indifferent_access'

class Syphon::ResourceDSL

  class Context < OpenStruct
    def initialize(type, parent)
      super()
      self.type  = type
      self.parent = parent
    end

    # emulate lexical scoping
    def method_missing(meth, *args, &block)
      case (meth.to_s[-1] == ?=)
      when true; super
      else super || (parent && parent.send(meth))
      end
    end
  end

  attr_reader :context
  alias_method :ctx, :context

  def initialize(opts = {})
    @valid_commands = opts[:commands]
    @resource_class = opts[:resource_class] || Syphon::Api::Resource 
    expose_valid_commands

    @resources = HashWithIndifferentAccess.new
    @context = Context.new(:root, nil)
    @context.namespace = ''
    @context_stack = []
  end

  def namespace(name, &block)
    new_context :namespace, block do
      ctx.namespace += "/#{name}"
    end
  end

  def resources(name, opts = {}, &block)
    new_context :resources, block do
      ctx.resource = @resource_class.new(name, @resources, ctx, opts)
      @resources[name] = ctx.resource
    end
  end

  # Not wrapped in context block since controller command can be called anywhere
  # legally
  #
  def controller(klass)
    case ctx.type
    when :root, :namespace
      ctx.super_controller = klass
    when :resources
      ctx.resource.controller = klass
    end
  end

  def model(klass)
    check_context_nesting(:inner)
    ctx.resource.model = klass
  end

  [:field, :join, :resource, :collection].each do |method|
    send(:define_method, method) do |*val|
      check_context_nesting(:inner)
      ctx.resource.send("#{method}s=", val)
    end
  end

private

  # hide all unsupported DSL commands
  #
  def expose_valid_commands
    return unless @valid_commands
    private_commands = \
      public_methods(false) - @valid_commands
    private_commands.each do |command|
      singleton_class.class_eval do
        private(command)
      end
    end
  end

  # create a new context frame
  #
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
    new_context = Context.new(type, @context)
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
      when :resources
        ctx.type != :root && ctx.type != :namespace 
      when :inner
        ctx.type != :resources
      else false
      end

    raise "You cannot call '#{new_context_type}' inside a '#{ctx.type}' block" if error
  end


  # init helper
  #
  def self.[](config, opts = {}, &definition)
    resources = {}
    resources.merge!(from_config(config, opts)) if config
    resources.merge!(from_proc(definition, opts)) if definition
    resources
  end

  def self.from_config(config, opts)
    resource_class = opts[:resource_class] || Syphon::Api::Resource

    config.reduce({}) do |resources, conf|
      conf = OpenStruct.new(conf)
      conf.only.map!(&:to_sym)
      resources[conf.name] = \
        resource_class.new(conf.name, resources, conf)
      resources
    end
  end

  def self.from_proc(definition, opts)
    dsl = self.new(opts)
    dsl.instance_eval(&definition)
    dsl.instance_variable_get('@resources')
  end

end
