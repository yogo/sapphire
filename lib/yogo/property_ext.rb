require 'yogo/project'

module Yogo
  module Collection
    class Property

      def association_collection_id
        if controlled_vocabulary_id
          self.controlled_vocabulary.data_collection.id
        elsif associated_schema_id 
          self.associated_schema.data_collection.id
        elsif associated_list_schema_id
          self.associated_list_schema.data_collection.id
        end
      end

      def association_column_id
        if controlled_vocabulary_id
          self.controlled_vocabulary_id
        elsif associated_schema_id 
          self.associated_schema_id
        elsif associated_list_schema_id
          self.associated_list_schema_id
        end
      end

    end
  end
end