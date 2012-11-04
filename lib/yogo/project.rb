require 'yogo/project'

# Extending the Yogo Project with new properties
# If you need additional properties in your Yogo::Project
# Just create properties and relationships 
# like you would for any datamapper model
# See below for examples:

module Yogo
  class Project
    # extend Permission
    # include Facet::DataMapper::Resource
    
    # property :investigator,    String, :required => false, :default => ''
    
    # has n, :memberships, :parent_key => [:id], :child_key => [:project_id], :model => 'Membership'
    # has n, :roles, :through => :memberships
    # has n, :users, :through => :memberships
    # 
    # after :create, :give_current_user_membership
    # before :destroy, :destroy_cleanup
    
    # Construct the models from the kefed diagram
    def build_models_from_kefed
      yogo_model.measurements.each do |measurement_uid, measurement|
        collection_opts = {:id => measurement_uid}
        
        kollection = self.data_collections.first_or_new(collection_opts)
        
        if Crux::YogoModel.is_asset_measurement?(measurement)
          collection_opts[:type] = 'Yogo::Collection::Asset'
        end
        
        collection_opts[:name] = measurement['label']
        kollection.attributes = collection_opts
        
        begin
          kollection.save
        rescue ::DataMapper::SaveFailureError 
          ::Rails.logger.info {"----- ERROR: Unable To Save Collection (#{kollection.attributes[:name]}) -----"}
          ::Rails.logger.info { kollection.inspect }
          ::Rails.logger.info {"Database Error(s): #{kollection.errors.full_messages}"}
          # flash[:error] = "ERROR: Unable to save collection (#{kollection.attributes[:name]})"
        end

        yogo_model.measurement_parameters(measurement_uid).each do |parameter|
          property = kollection.schema.first_or_new(:kefed_uid => parameter['uid'])
          attributes = { 
            :name => parameter['label'], 
            :type  => Crux::YogoModel.legacy_type(parameter),
            :options => {:required => false},
            :kefed_uid => parameter['uid']
          }
          property[:type] = attributes[:type]
          # if property.class == Yogo::Collection::Property::Boolean
          #   debugger
          # end
          property.attributes = attributes  
          
          begin
           result = property.save unless property.new?
          rescue ::DataMapper::SaveFailureError 
            ::Rails.logger.info {"----- ERROR: Unable To Save Property (#{property.attributes[:name]}) -----"}
            ::Rails.logger.info { property.inspect }
            ::Rails.logger.info {"Database Error(s): #{property.errors.full_messages}"}
            # flash[:error] = "ERROR: Unable to save collection (#{property.attributes[:name]})"
          end
        end

        # clean up orphaned non-asset columns (this can cause data loss)
        # the orphaned non-asset column will have the same kefed_uid as the collection's id
        if(kollection.kind_of?(Yogo::Collection::Asset))
          orphan = kollection.schema.first(:kefed_uid => kollection.id.to_s.upcase)
          orphan.destroy if orphan
        end
        #debugger
        begin
          kollection.save
        rescue ::DataMapper::SaveFailureError 
          ::Rails.logger.info {"----- ERROR: Unable To Save Collection (#{kollection.attributes[:name]}) -----"}
          ::Rails.logger.info { kollection.inspect }
          ::Rails.logger.info {"Database Error(s): #{kollection.errors.full_messages}"}
          # flash[:error] = "ERROR: Unable to save collection (#{kollection.attributes[:name]})"
        end
      end
    end

#     def root_model
#       data_collections.first
#     end
# 
#     # TODO: Optimize me, this is slow
#     def kefed_ordered_data_collections
#       yogo_model.ordered_measurements.map { |ym| 
#         data_collections.select{|dc| dc.id.to_s == ym['uid'].downcase }[0]
#       }.compact
#     end
# 
#     def permissions_for(user)
#       @_permissions_for ||= {}
#       @_permissions_for[user] ||= begin
#         base_permission = []
#         base_permission << "#{permission_base_name}$retrieve" unless self.is_private?
#         return base_permission if user.nil?
#         (super + base_permission + user.memberships(:project_id => self.id).roles.map{|r| r.actions }).flatten.uniq
#       end
#     end
# 
#     # Temporary maintenance method that can be deprecated after adding kefed_uid
#     # to the live data
#     def self.fix_property_kefed_uids
#       self.all.each do |proj|
#         proj.data_collections.each do |coll|
#           proj.yogo_model.measurement_parameters(coll.id).each do |param|
#             prop = coll.schema.first(:name => param['label'])
#             prop.update(:kefed_uid => param['uid']) if prop
#           end
#         end
#       end
#     end
#     
#     private
#     
#     def destroy_cleanup
#       memberships.destroy
#     end
#     
#     def give_current_user_membership
#       unless User.current.nil?
#         Membership.create(:user => User.current, :project => self, :role => Role.first(:position => 1))
#       end
#     end
# 
#   end
end
