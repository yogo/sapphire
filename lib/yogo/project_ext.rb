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
      search_str = search_str.gsub(/\b\s+\b/,' | ') 
      unless search_str.blank?
        data_collections.each do |dc|
          #we will search on all schema properties that are strings
          search_schemas = dc.schema.select{ |s| 
            s.type == Yogo::Collection::Property::String ||
            s.type == Yogo::Collection::Property::Text
          }
          conds = search_schemas.map do |schema| 
              "field_#{schema.id.to_s.gsub('-','_')} @@ tsquery(?)" 
            end
          conds_array = [conds.join(" OR ")]
          search_schemas.count.times{ conds_array << escape_string(search_str) }
          results[dc.id.to_s] = dc.items.all(:conditions => conds_array)
        end
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
  
  module Collection
      class Asset
        module ModelProperties
          def self.extended(model)
            model.class_eval do
              property :deleted_at,           ::DataMapper::Property::ParanoidDateTime
              property :updated_comment,      ::DataMapper::Property::Text,    :lazy=>false
              property :provenance_comment,   ::DataMapper::Property::Text, :required=>false, :required =>false
              property :updated_by,           ::DataMapper::Property::Integer, :lazy=>false, :required=>false
              property :original_uid,          ::DataMapper::Property::UUID, :required =>false
             
              before :save, :make_version

              #copies the pre-saved item to a version and then deletes the version
              #this will make a version for a newly created record 
              def make_version
                # check to see if this is a version record because it is we do nothing                
                if self.original_uid.nil?
                  #this is a new or updated record so make a new version
                  dirty_props = (self.dirty_attributes.keys.map{|k| k.name.to_s }-['id','updated_at','provenance_comment','deleted_at']).join(', ')
                  self.updated_comment = "UPDATED_FIELDS: #{dirty_props}"
                  att = self.attributes
                  att.delete(:id)
                  att = att.merge({:original_uid => self.id})
                  version = self.model.collection.items.create(att)
                  version.destroy
                end
              end
              
              #pulls all the versions of the current item
              #NOTE that a record that has just been created WILL have a version which is
              #an exact copy
              def versions
                self.model.collection.items.with_deleted.all(:original_uid=>self.id.to_s, :order=>[:deleted_at])
              end
            end
          end
        end #modelProperties
      end #asset
  end #collection
end# end yogo