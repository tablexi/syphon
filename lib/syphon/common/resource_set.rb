require 'active_support/hash_with_indifferent_access'
require 'json'

class Syphon::ResourceSet < HashWithIndifferentAccess

  def find(resource)
    res = \
      if resource.is_a?(Class)
        self.detect { |n,r| r.model_class == resource }
      else
        self.detect { |n,r| r.resource_name == resource || r.collection_name == resource }
      end

    res && res.last
  end

  def to_json
    serialize.to_json
  end

private

  def serialize
    map { |n, r| r.serialize }
  end

end
