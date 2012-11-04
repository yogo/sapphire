require 'yogo/collection/data'

module Yogo
  module Collection
    class Data
      def asset_collection?
        self.kind_of?(Yogo::Collection::Asset)
      end
    
      def data_collection?
        self.kind_of?(Yogo::Collection::Data)
      end
    end
  end
end