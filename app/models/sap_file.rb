#  sap_file.rb
#  Sapphire File Assest

class SapFile
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, Text, :required => true
  property :filepath, Text, :required=>true
  
  has n, :meta_tags, :through => Resource
end