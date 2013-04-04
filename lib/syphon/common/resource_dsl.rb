require 'ostruct'
require 'active_support/core_ext/string'
require 'active_support/hash_with_indifferent_access'

class Syphon::ResourceDSL

  class Context < OpenStruct
    def initialize(type, parent = nil)
      super()
      self.type  = type
      self.parent = parent
      self.namespace = '' if type == :root
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
    @resource_class = opts[:resource_class] || Syphon::Api::Resource 
    add_resource_commands

    @resources = HashWithIndifferentAccess.new
    @context_stack = []
    @context = Context.new(:root)
  end

  def namespace(name, &block)
    new_context :namespace, block do
      ctx.namespace += "/#{name}"
    end
  end

  def resource(name, opts = {}, &block)
    new_context :resources, block do
      ctx.resource = @resource_class.new(name, @resources, ctx, opts)
      @resources[name] = ctx.resource
    end
  end

  def super_controller(klass)
    check_context_nesting(:super_controller)
    ctx.super_controller = klass
  end

private

  def add_resource_commands
    @resource_class.commands.each do |cmd, opts|
      define_singleton_method(cmd) do |*val|
        val = val.first unless opts[:splat]
        check_context_nesting(:inner)
        ctx.resource.send("#{cmd}=", val)
      end
    end
  end

  # create a new context frame
  #
  def new_context(type, proc = nil)
    create_new_context(type)

    # run context initializer
    yield if block_given?

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
      when :super_controller
        ctx.type != :root && ctx.type != :namespace
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
