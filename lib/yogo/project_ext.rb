require 'yogo/project'

module Yogo
  class Project
    
    property :record_count, Integer
    
    has n, :memberships, :model=>"Membership"
    alias :members :memberships
    alias :collections :data_collections

    #make a new collection with schema from CSV file
    def collection_from_file(name, new_file, collection=nil)
      csv = CSV.read(new_file)
      if collection
        new_data_collection = collection
      else
        new_data_collection = self.data_collections.first_or_create(:name=>name,:type => Yogo::Collection::Asset, :category=>'')
      end
      header_row = csv[0]
      header_row.each do |field|
        unless field=="file" || field == "File"
          schema = new_data_collection.schema.first_or_create(:name=>field, :type=>Yogo::Collection::Property::String)
        end
      end
      new_data_collection
    end
    
    #perform full-text search using the postgres tsvector fields
    def full_text_search(search_str)
      results = {}
      search_str = search_str.gsub(/\b\s+\b/,' | ') 
      unless search_str.blank?
        data_collections.each do |dc|
          #we will search on all schema properties that are strings
          search_schemas = dc.schema.select{ |s| 
            s.type == Yogo::Collection::Property::String ||
            s.type == Yogo::Collection::Property::Text
          }
          if !search_schemas.empty?
            conds = search_schemas.map do |schema| 
                "field_#{schema.id.to_s.gsub('-','_')} @@ tsquery(?)" 
              end
            conds_array = [conds.join(" OR ")]
            search_schemas.count.times{ conds_array << escape_string(search_str) }
            results[dc.id.to_s] = dc.items.all(:conditions => conds_array)
          end
        end
      end
      results
    end
    
    def process_zip_file_to_collection(filename, original_name, collection=nil)
      folder_name ="tmp/uploads/#{Time.now.to_i.to_s}"
      sys_str="unzip #{filename} -d #{folder_name}"
      system(sys_str)
      data_collection = self.collection_from_file(original_name, folder_name+"/index.csv",collection)
      puts data_collection.name + "(#{data_collection.new?})"
      self.process_zip_file_data_to_collection(folder_name, "index.csv", data_collection.id)
      data_collection
    end
    
    def process_zip_file_data_to_collection(path, file, collection_id)
      collection = Yogo::Collection::Asset.get(collection_id)
      csv = CSV.read(path+'/'+file)
      puts header_row = csv[0]
      puts collection.schema.map{|k| k.name}.to_s
      (1..csv.length-1).each do |j|
        item = collection.items.new
        i=0
        header_row.each{|h| h.capitalize == "File" ? item.file =File.new("#{path}/#{csv[j][i].strip}") : item[h]=csv[j][i]; i+=1}
        collection.schema.each do |field|
          if item[field.name].blank?
            item[field.name]=nil
          end
        end
        item.save
      end
    end

    def update_stats
      self.record_count = 0
      self.data_collections.each do |col|
        self.record_count += col.items.count
      end
      self.save
    end
    
    def public?
      !private?
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