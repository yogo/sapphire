# Getting Started/Installation:

1. Install git on your machine
We recommend using RVM you can find directions for install and use here: http://beginrescueend.com/ 
2. Fetch yogo sapphire project from the github repository at https://github.com/yogo/sapphire using $ git clone git@github.com:yogo/sapphire.git
3. Then get into the sapphire directory created and if you are using rvm switch to ruby version 1.9.3 or greater and create an rvm gemset.
4. execute a bundle install - this will install all the gems
5. run rake db:migrate - this will setup the database with the correct initial static tables

now you have a base Rails stack applicaton that uses the Yogo Framework that you can begin creating models and views for :)

## Making a new project:

    project   = Yogo::Project.create(:name=>”test”)

## Extending a Yogo Project Model:

In lib/yogo the is a file stub called “project_ext.rb” and you can add properties to that to extend your base Project Model- there are comments and examples in this file to help.

## Making a Project a Repository Manage:

This will allow a Yogo Project to become a new database and house all data related to it within it’s own repository.  This also allows the repository to be protected by the authorizations related to the project(if the appropriate functions and memberships have been added previously) TODO - turn this block along with the associated models into a gem or something
    
    has n, :memberships, :parent_key => [:id], :child_key => [:project_id], :model => 'Membership'
    has n, :users, :through => :memberships
    has n, :roles, :through => :memberships

    after :create, :give_current_user_membership
    def give_current_user_membership
      unless User.current.nil?
        Membership.create(:user => User.current, :project => self, :role => Role.first(:position => 1))
      end
    end
    
within the project model add:

require 'yogo/datamapper/repository_manager' 
include Yogo::DataMapper::RepositoryManager

## Making a new model in a yogo collection

### Adding a new Collection

    coll = Yogo::Collection::Asset.new
    project.data_collections << coll
    c = project.data_collections.first
OR
    c = project.data_collections.create(:name=>"foobar")
    
### Adding a new property to the collection(model):

    foo = c.shema.new
    foo.name =  “Color”
    foo.type = Yogo::Collection::Property::String
    foo.save
    
    new_property = project.data_collections.last.schema.create(:name => "Count", :type=>Yogo::Collection::Property::Integer)
### Making the new table

The table is not created until a item is added.  This is also how a new item is added.

    my_item = c.items.new
    my_item[“Color”] = “blue”
    my_item.save
    
    another_item = c.items.new
    another_item["Count"] = 1
    another_item.save