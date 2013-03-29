class ActionDispatch::Routing::Mapper

  def nested_namespace(namespaces, &block)
    if namespaces.empty?
      block.call
    else
      namespace namespaces.shift do 
        nested_namespace(namespaces, &block)
      end
    end
  end

end
