require 'yogo/project'

module Yogo
  module Collection
    class Data

      after :update, :update_stats

      def update_stats
        self.project.update_stats
      end

      def public?
        !private?
      end
    end
  end
end