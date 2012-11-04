require 'yogo/project'

module Yogo
  class Project
    
    property :record_count, Integer
    
    has n, :memberships, :model=>"Membership"
    alias :members :memberships

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

    # Construct the models from the kefed diagram
    def build_models_from_kefed
      yogo_model.measurements.each do |measurement_uid, measurement|
        collection_opts = {:id => measurement_uid}
        
        kollection = self.data_collections.first_or_new(collection_opts)
        
        if Crux::YogoModel.is_asset_measurement?(measurement)
          collection_opts[:type] = 'Yogo::Collection::Asset'
        end
        
        collection_opts[:name] = measurement['label']
        kollection.attributes = collection_opts
        
        begin
          kollection.save
        rescue ::DataMapper::SaveFailureError 
          ::Rails.logger.info {"----- ERROR: Unable To Save Collection (#{kollection.attributes[:name]}) -----"}
          ::Rails.logger.info { kollection.inspect }
          ::Rails.logger.info {"Database Error(s): #{kollection.errors.full_messages}"}
          # flash[:error] = "ERROR: Unable to save collection (#{kollection.attributes[:name]})"
        end

        yogo_model.measurement_parameters(measurement_uid).each do |parameter|
          property = kollection.schema.first_or_new(:kefed_uid => parameter['uid'])
          attributes = { 
            :name => parameter['label'], 
            :type  => Crux::YogoModel.legacy_type(parameter),
            :options => {:required => false},
            :kefed_uid => parameter['uid']
          }
          property[:type] = attributes[:type]
          # if property.class == Yogo::Collection::Property::Boolean
          #   debugger
          # end
          property.attributes = attributes  
          
          begin
           result = property.save unless property.new?
          rescue ::DataMapper::SaveFailureError 
            ::Rails.logger.info {"----- ERROR: Unable To Save Property (#{property.attributes[:name]}) -----"}
            ::Rails.logger.info { property.inspect }
            ::Rails.logger.info {"Database Error(s): #{property.errors.full_messages}"}
            # flash[:error] = "ERROR: Unable to save collection (#{property.attributes[:name]})"
          end
        end

        # clean up orphaned non-asset columns (this can cause data loss)
        # the orphaned non-asset column will have the same kefed_uid as the collection's id
        if(kollection.kind_of?(Yogo::Collection::Asset))
          orphan = kollection.schema.first(:kefed_uid => kollection.id.to_s.upcase)
          orphan.destroy if orphan
        end
        #debugger
        begin
          kollection.save
        rescue ::DataMapper::SaveFailureError 
          ::Rails.logger.info {"----- ERROR: Unable To Save Collection (#{kollection.attributes[:name]}) -----"}
          ::Rails.logger.info { kollection.inspect }
          ::Rails.logger.info {"Database Error(s): #{kollection.errors.full_messages}"}
          # flash[:error] = "ERROR: Unable to save collection (#{kollection.attributes[:name]})"
        end
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