require 'active_support/hash_with_indifferent_access'

class Syphon::ResourceSet < HashWithIndifferentAccess

  def find(resource)
    res = self.detect { |n,r| r.resource_name == resource ||
                              r.collection_name == resource ||
                              r.model_class == resource }
    res && res.last
  end

end
