require 'yogo/project'

module Yogo
  module Collection
    class Data

      after :update, :update_stats

      def update_stats
        self.project.update_stats
      end
      
      #return an array of [item value, item id]
      def items_array(field)
        self.items.all(:fields=>["#{field}", :id]).map{|i| [(i[field].nil? ? "" : i[field]), i.id.to_s]}
        str = self.items.all(:fields=>["#{field}", :id]).to_json
        JSON.parse(str).map{|i| [(i[field].nil? ? "" : i[field]), i['id']]}
      end
      
      #return an array of [item value, item value]
      def items_value_array(field)
        #self.items.all(:fields=>["#{field}", :id]).map{|i| [(i[field].nil? ? "" : i[field]), (i[field].nil? ? "" : i[field])]}
        str = self.items.all(:fields=>["#{field}", :id]).to_json
        JSON.parse(str).map{|i| [(i[field].nil? ? "" : i[field]), (i[field].nil? ? "" : i[field])]}
      end
      
      #return a array of [item value, json_association] for use in 
      def items_json_array(field, project_id, collection_id, term="")
        #pql= "SELECT * FROM pg_prepared_xacts"
        #repository.adapter.select(pql)
        #sql = "Select #{field}, id FROM '#{collection_id.to_s.gsub('-','_')}s'"
        #debugger
        #results = repository.adapter.select(sql)
        #debugger
        #self.items(:fields=>["#{field}", :id])
        #self.items.all(:fields=>["#{field}", :id]).map{|i| [i[field], '{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+(i[field].nil? ? "" : i[field])+'"}}'] }
        str = self.items.all(:fields=>["#{field}", :id], "#{field}".to_sym.like=>"%#{term}%").to_json
        JSON.parse(str).map{|i| [i[field], '{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i['id']+'", "display": "'+(i[field].nil? ? "" : i[field])+'"}}'] }
      end
      
       #return a array of [item value, json_association] for use in 
        def items_json_array_paginate(field, project_id, collection_id, term="", page)
          #pql= "SELECT * FROM pg_prepared_xacts"
          #repository.adapter.select(pql)
          #sql = "Select #{field}, id FROM '#{collection_id.to_s.gsub('-','_')}s'"
          #debugger
          #results = repository.adapter.select(sql)
          #debugger
          #self.items(:fields=>["#{field}", :id])
          #self.items.all(:fields=>["#{field}", :id]).map{|i| [i[field], '{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+(i[field].nil? ? "" : i[field])+'"}}'] }
          str = self.items.paginate(:page=>page, :fields=>["#{field}", :id], "#{field}".to_sym.like=>"%#{term}%").to_json
          JSON.parse(str).map{|i| [i[field], '{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i['id']+'", "display": "'+(i[field].nil? ? "" : i[field])+'"}}'] }
        end
      def public?
        !private?
      end
    end
  
    class Asset
      #return an array of [item value, item id]
      def files_json_array(project_id, collection_id)
        self.items.map{|i| [i.original_filename.to_s,'{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+i.original_filename.to_s+'"}}'] }
      end
      
      
      def files_array(project_id, collection_id)
        self.items.map{|i| [i.original_filename.to_s,i.original_filename.to_s] }
      end
    end
  end
end