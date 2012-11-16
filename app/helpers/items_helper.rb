module ItemsHelper
  
  def field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i[schema.name]] }
  end
  
  def associated_field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],'{"project":{"id": "'+schema.data_collection.project_id+'"}, "collection":{"id": "'+schema.data_collection.id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+i[schema.name]+'"}}'] }
  end
end
