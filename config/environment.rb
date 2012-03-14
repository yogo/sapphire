# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Sapphire::Application.initialize!

#extend the Struct class
class Struct
   def to_hash
     Hash[*members.zip(values).flatten]
   end
 end
#extend Array so that raw sql results can be converted to json easily
#assumes this is an array of Structs or Objects that have the to_hash method
class Array
  def sql_to_json
    self.map{|k| k.to_hash}.to_json
  end
end

module DataMapper
  def self.raw_select(dm_query)
    statement, bind_vars = repository.adapter.send(:select_statement, dm_query.query)
    sql = repository.adapter.send(:open_connection).create_command(statement).send(:escape_sql, bind_vars)
    repository.adapter.select(sql)
  end
end