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
    
  end #end project
end# end yogo