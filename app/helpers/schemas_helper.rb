module SchemasHelper
  def property_types_opts
    Yogo::Collection::Property::COMMON_PROPERTIES.map(&:to_s).zip(
      Yogo::Collection::Property::COMMON_PROPERTIES.map{|p| "Yogo::Collection::Property::" + p.to_s}
    )
  end
  
  def controlled_vocabulary_opts
    @project.data_collections.schema.map{|s| [s.data_collection.name + " > " + s.name, s.id] }
  end
  
end
