module ItemsHelper
  
  def field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i[schema.name]] }
  end
  
  def predicate_options()
    predicates = Array.new([["is equal to","="],["is NOT equal to","not"],["is like","like"],["is greater than","gt"], ["is greater than or equal to","gte"],["is less than","lt"],["is less than or equal to", "lte"]])
  end
  
  def associated_field_value_options(schema)
    schema.data_collection.items_json_array(schema.field_name, schema.data_collection.project_id, schema.data_collection.id)
  end
  
  def associated_field_display_options(schema)
    schema.data_collection.items_value_array(schema.field_name)
  end
  
  def associated_file_options(file_collection)
    file_collection.files_array(file_collection.project_id, file_collection.id)
  end
end
