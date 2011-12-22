
class SapFile
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, Text, :required => true
  property :filepath, Text, :required=>true
end