require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object'

module Syphon::Inflections

  # Fixes stupid safe_constantize behavior where
  # "NS1::NS2::SomeClass".safe_constantize returns 
  # ::SomeClass if it exists
  #
  def constantize(name)
    const = name.to_s.safe_constantize
    const.to_s == name ? const : nil
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
