module ItemsHelper
  
  def field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i[schema.name]] }
  end
  
  def associated_field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i.id.to_s] }
  end
end
