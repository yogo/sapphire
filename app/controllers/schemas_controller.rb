class SchemasController < ApplicationController
    before_filter :get_dependencies  

    def index
      @schema = @collection.schema
    end

    def show
      @schema = @collection.schema.get(params[:id])
    end

    def edit
      @schema = @collection.schema.get(params[:id])
    end

    def update
      @schema = @collection.schema.get(params[:id])

      if params[:schema][:association_column_id]
        case params[:schema][:type]
        when 'controlled_vocabulary'
          params[:schema][:controlled_vocabulary_id] = params[:schema][:association_column_id]
          # This is a problem. We can't change the type, but the prepop list will be potentially nonsensical (prompting strings for an Int column for example)
          # params[:schema][:type] = Yogo::Collection::Property.get(params[:schema][:association_column]).type
        when 'association'
          params[:schema][:associated_schema_id] = params[:schema][:association_column_id]
        when 'list_association'
          params[:schema][:associated_list_schema_id] = params[:schema][:association_column_id]
        end
        params[:schema].delete(:association_column_id)
      end

      params[:schema].delete(:association_collection_id) if params[:schema][:association_collection_id]

      # Type not allowed to be changed
      params[:schema].delete(:type) if params[:schema][:type]

      # if params[:schema][:associated_schema_id].blank?
      #   params[:schema].delete(:associated_schema_id)
      # elsif @schema.associated_schema_id != params[:schema][:associated_schema_id]  
      #   if Yogo::Collection::Property.get(params[:schema][:associated_schema_id]).data_collection_id == @schema.associated_schema.data_collection_id
      #     #do nothing because the existing UIDs will still work we have just changed the display column
      #     flash[:notice] = "Column was Updated with different display column from existing Association."
      #   else
      #     @schema.deleted_at = Time.now
      #     @schema.save
      #     @schema = @collection.schema.create(params[:schema])
      #     flash[:notice] = "Column was Updated with new Association."
      #   end
      # end

      if @schema.update(params[:schema])
        flash[:notice] = "Column updated!"
        @schema.update_position
      else
        flash[:error] = "Column failed to update! Errors: " + @schema.errors.full_messages.join(', ')
      end

      redirect_to :back
    end
    
    #expects the delete_at datetime in params[:deleted_at]
    def restore
       @schema = @collection.schema.get(params[:schema_id])
       old_schema =Yogo::Collection::Property.with_deleted.first(:original_uid=>@schema.id, :deleted_at => params[:deleted_at])
       att = old_schema.attributes
       att.delete(:deleted_at)
       att.delete(:original_uid)
       att.delete(:id)
       if @schema.update(att)
         flash[:notice] = "Column Restored Successfully!"
         redirect_to edit_project_collection_schema_path(@project, @collection, @schema)
       else
         flash[:error] = "Column failed to restore! Errors: " + @schema.errors.full_messages.join(', ')
         render :edit
       end
    end
    
    def new
    end
    
    def destroy
      @schema = @collection.schema.get(params[:id])
      @schema.deleted_at = Time.now
      if @schema.save
       flash[:notice] = "Column was Deleted."
      else
        flash[:error] = "Column failed to Delete Errors: " + @schema.errors.full_messages.join(', ')
      end
      redirect_to :back
    end
    
    def create
      # Funnily enough, we don't care about the association_collection at all (that comes from the column)
      if params[:schema][:association_column_id]
        case params[:schema][:type]
        when 'controlled_vocabulary'
          params[:schema][:controlled_vocabulary_id] = params[:schema].delete(:association_column_id)
          params[:schema][:type] = Yogo::Collection::Property.get(params[:schema][:controlled_vocabulary_id]).type
        when 'association'
          params[:schema][:associated_schema_id] = params[:schema].delete(:association_column_id)
          
          params[:schema][:type] = Yogo::Collection::Property::Text
        when 'list_association'
          params[:schema][:associated_list_schema_id] = params[:schema].delete(:association_column_id)
          params[:schema][:type] = Yogo::Collection::Property::Text
        end
      elsif params[:schema][:type] =='File'
        params[:schema][:type] = Yogo::Collection::Property::Text
        params[:schema][:is_file] = true
      elsif params[:schema][:type] =='seafile'
        params[:schema][:description] = {:seafile_repo => params[:schema].delete(:seafile_library_id), :seafile_directory => params[:schema].delete(:seafile_directtory_id}
        params[:schema][:is_seaffile] = true
        params[:schema][:type] = Yogo::Collection::Property::Text
      else
        params[:schema].delete(:association_column_id)
      end
      # There is only a column if someone selects a collection, but 
      # a blank association_collection is always sent.
      # The 'if' is just a defensive programming tic (though it makes sense from an API perspective...).
      params[:schema].delete(:association_collection_id) if params[:schema][:association_collection_id]
      
      logger.info '!!!! PARAMS: ' + params.inspect
      @schema = @collection.schema.new(params[:schema])
      if @schema.save
        @schema.update_position
        if @schema.type.to_s =~ /String|Text|JSON/
          #force table creation
          @collection.items.new
          sql="ALTER TABLE #{'"'+@collection.id.to_s.gsub('-','_')+'s"'} ADD COLUMN field_#{@schema.id.to_s.gsub('-','_')}_search_index tsvector;"
          repository.adapter.execute(sql)
          sql = "UPDATE #{'"'+@collection.id.to_s.gsub('-','_')+'s"'} SET field_#{@schema.id.to_s.gsub('-','_')}_search_index = to_tsvector('english', coalesce(field_#{@schema.id.to_s.gsub('-','_')},''));"
          repository.adapter.execute(sql)
          sql = "CREATE TRIGGER field_#{@schema.id.to_s.gsub('-','_')} BEFORE INSERT OR UPDATE ON #{'"'+@collection.id.to_s.gsub('-','_')+'s"'} FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger(field_#{@schema.id.to_s.gsub('-','_')}_search_index, 'pg_catalog.english', field_#{@schema.id.to_s.gsub('-','_')});"
          repository.adapter.execute(sql)
        end
        flash[:notice] = "Column created successfully!"
      else
        flash[:error] = "Column failed to save! Errors: " + @schema.errors.full_messages.join(', ')
      end
      redirect_to project_collection_path(@project,@collection)
    end
    
  private
    def get_dependencies
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.data_collections.get(params[:collection_id])      
    end
end
