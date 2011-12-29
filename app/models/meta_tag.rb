#  sap_file.rb
#  Sapphire File Assest
#  Author:  Sean Cleveland

class MetaTag
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, Text, :required => true

  has n, :sap_files, :through => Resource
end