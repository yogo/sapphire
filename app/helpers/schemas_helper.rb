module SchemasHelper
  def property_types_opts
    Yogo::Collection::Property::COMMON_PROPERTIES.map(&:to_s).zip(
      Yogo::Collection::Property::COMMON_PROPERTIES.map{|p| "Yogo::Collection::Property::" + p.to_s}
    )
  end
end
