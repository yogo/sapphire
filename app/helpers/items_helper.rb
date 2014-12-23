module ItemsHelper
  
  def field_value_options(schema)
    schema.data_collection.items.map{|i| [i[schema.name],i[schema.name]] }
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


  def seafile_file_options(field)
    dir  = JSON.parse(field.description)["seafile_directory"]
    json_files = current_user.seafile_files(JSON.parse(field.description)["seafile_repo"], 
              dir.include?('root_repo')  ? "/" : JSON.parse(dir)["name"])
    #file_array = [JSON.parse(field.description)["seafile_repo"], JSON.parse(field.description)["seafile_directory"] ]
    file_array = []#[JSON.parse(field.description)["seafile_directory"]["name"],JSON.parse(dir)["name"]]
    json_files.each do |file|
      if file["type"] == "file"
      file_array << [file["name"],file.to_json.to_s]
      end
    end
    file_array
  end
end
