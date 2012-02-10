require 'yogo/project'

module Yogo
  class Project


    def collection_from_file(name, new_file)
      csv = CSV.read(new_file)
      new_data_collection = self.data_collections.create(:name=>name,:type => Yogo::Collection::Asset)
      header_row = csv[0]
      header_row.each do |field|
        schema = new_data_collection.schema.new(:name=>field, :type=>Yogo::Collection::Property::String)
        schema.save
      end
      new_data_collection
    end
    
    def full_text_search(search_str)
      results = {}
      data_collections.each do |dc|
        #we will search on all schema properties that are strings
        search_schemas = dc.schema.select{ |s| s.type == Yogo::Collection::Property::String }
        conds = search_schemas.map do |schema| 
            "field_#{schema.id.to_s.gsub('-','_')} @@ plainto_tsquery(?)" 
          end
        conds_array = [conds.join(" OR ")]
        search_schemas.count.times{ conds_array << escape_string(search_str) }
        results[dc.id.to_s] = dc.items.all(:conditions => conds_array)
      end
      results
    end
    
    private 
    
    def escape_string(str)
      str.gsub(/([\0\n\r\032\'\"\\])/) do
        case $1
        when "\0" then "\\0"
        when "\n" then "\\n"
        when "\r" then "\\r"
        when "\032" then "\\Z"
        when "'"  then "''"
        else "\\"+$1
        end
      end
    end
    
  end #end project
end# end yogo