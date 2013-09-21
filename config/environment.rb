# Load the rails application
require File.expand_path('../application', __FILE__)


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
  def sql_to_xml
    self.map{|k| k.to_hash}.to_xml
  end
  def sql_to_csv
    unless self[0].nil?
      header = self[0].to_hash.keys.map{|k| k}.join(',') + "\n"
      header << self.map{|k| k.to_a.to_csv}.join("\n")
    end
  end
  def sql_to_datatable_json
      unless self[0].nil?
        #header = self[0].to_hash.keys.map{|k| k}.join(',') + "\n"
        data={}
        data[:aaData] = self.map{|k| k.to_a}
        data[:sEcho] = 1
        data[:iTotalRecords] = data[:aaData].count
        data[:iTotalDisplayRecords] = data[:iTotalRecords]
        data.to_json
      end
    end
end

class String
  def valid_float?
    # The double negation turns this into an actual boolean true - if you're 
    # okay with "truthy" values (like 0.0), you can remove it.
    !!Float(self) rescue false
  end
  
  def escape_single_quotes
    self.gsub(/[']/, '\\\\\'')
  end
  def escape_quotes_for_sql
    self.gsub(/[']/, "''").gsub('"', '\"')
  end
end

module DataMapper
  def self.raw_select(dm_query)
    statement, bind_vars = repository.adapter.send(:select_statement, dm_query.query)
    sql = repository.adapter.send(:open_connection).create_command(statement).send(:escape_sql, bind_vars)
    repository.adapter.select(sql)
  end
  
  def self.generate_sql_select(dm_query)
    statement, bind_vars = repository.adapter.send(:select_statement, dm_query.query)
    sql = repository.adapter.send(:open_connection).create_command(statement).send(:escape_sql, bind_vars)
  end
  
  def self.generate_sql_execute(dm_query)
    statement, bind_vars = repository.adapter.send(:insert_statement, dm_query.query)
    sql = repository.adapter.send(:open_connection).create_command(statement).send(:escape_sql, bind_vars)
  end
  def self.sanitize(value)
   repository.adapter.send(:quote_name, value)
  end
  
end

# Initialize the rails application
Sapphire::Application.initialize!
