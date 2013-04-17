require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object'

module Syphon::Inflections

  # ActiveSupport safe_constantize forgets to check if const_missing magically
  # loaded a module with the same name but at a lower nesting level.
  #
  def constantize(camel_cased_word)
    begin
      names = camel_cased_word.to_s.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        new_constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
        if constant != Object && new_constant.to_s == name
          constant = nil
          break
        else constant = new_constant
        end
      end
      constant
    rescue NameError => e
      raise unless e.message =~ /(uninitialized constant|wrong constant name)/ || e.name.to_s == camel_cased_word.to_s
    rescue ArgumentError => e
      raise unless e.message =~ /not missing constant/
    end
  end

  def classify(name)
    name.to_s.classify
  end

  def controllerize(name)
    "#{name.to_s.camelize}Controller"
  end

  def singularize(name)
    name.to_s.singularize
  end

  def pluralize(name)
    name.to_s.pluralize
  end

end
