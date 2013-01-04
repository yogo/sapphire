module ItemsHelper
  
  def field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i[schema.name]] }
  end
  
  def associated_field_value_options(schema)
    project_id = schema.data_collection.project_id
    collection_id = schema.data_collection.id
    schema_name = schema.name
    items = schema.data_collection.items
    items.map{|i| [i[schema_name],'{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+i[schema_name]+'"}}'] }
  end
  
  def associated_field_display_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i[schema.name]] }
  end
  
  def associated_file_options(file_collection)
    file_collection.items.map{|i| [i.original_filename.to_s,'{"project":{"id": "'+file_collection.project_id+'"}, "collection":{"id": "'+file_collection.id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+i.original_filename.to_s+'"}}'] }
  end
end
