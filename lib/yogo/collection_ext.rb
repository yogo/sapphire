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
        DataMapper.raw_select(self.items).map{|i| [i[field], i.id.to_s]}
      end
      
      #return an array of [item value, item value]
      def items_value_array(field)
        DataMapper.raw_select(self.items).map{|i| [i[field], i[field]]}
      end
      
      #return a array of [item value, json_association] for use in 
      def items_json_array(field, project_id, collection_id)
        DataMapper.raw_select(self.items).map{|i| [i[field], '{"project":{"id": "'+project_id+'"}, "collection":{"id": "'+collection_id+'"},"item":{"id": "'+i.id.to_s+'", "display": "'+i[field]+'"}}'] }
      end
      def public?
        !private?
      end
    end
  end
end