class Membership

  include DataMapper::Resource
 
  property :id, Serial
  
  belongs_to :user
  belongs_to :project, :model=>"Yogo::Project"

end
