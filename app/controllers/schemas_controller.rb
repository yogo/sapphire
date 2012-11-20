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
      @versions = Yogo::Collection::Property.with_deleted.all(:original_uid=>@schema.id, :order=>[:deleted_at])
    end

    def update
      @schema = @collection.schema.get(params[:id])
      if params[:schema][:controlled_vocabulary_id].blank?
        params[:schema][:controlled_vocabulary_id] = nil
      end
      if params[:schema][:associated_schema_id].blank?
        params[:schema].delete(:associated_schema_id)
      elsif !@schema.associated_schema_id.nil?  && @schema.associated_schema_id !=params[:schema][:associated_schema_id]  
        if Yogo::Collection::Property.get(params[:schema][:associated_schema_id]).data_collection_id == @schema.associated_schema.data_collection_id
          #do nothing because the existing UIDs will still work we have just changed the display column
          flash[:notice] = "Schema was Updated with different column from existing Association."
        else
          @schema.deleted_at = Time.now
          @schema.save
          @schema = @collection.schema.create(params[:schema])
          flash[:notice] = "Schema was Updated with new Association."
          redirect_to project_collection_path(@project,@collection)
          return
        end
      end
      @schema = @collection.schema.get(params[:id])
      if @schema.update(params[:schema])
        # success
        @schema.update_position
        redirect_to project_collection_path(@project,@collection)
      else
        # fail
        render :edit
      end
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
         flash[:notice] = "Schema Restored Successfully!"
         redirect_to edit_project_collection_schema_path(@project, @collection, @schema)
       else
         flash[:error] = "Schema failed to restore!"
         render :edit
       end
    end
    
    def new
      @schema = @collection.schema.new
    end
    
    def destroy
      @schema = @collection.schema.get(params[:id])
      @schema.deleted_at = Time.now
      if @schema.save
       flash[:notice] = "Schema was Deleted."
        redirect_to project_collection_path(@project,@collection)
      else
        flash[:error] = "Schema failed to Delete"
        redirect_to project_collection_path(@project,@collection)
      end
    end
    
    def create
      if params[:schema][:controlled_vocabulary_id].blank?
        params[:schema].delete(:controlled_vocabulary_id)
      end
      if params[:schema][:associated_schema_id].blank?
        params[:schema].delete(:associated_schema_id)
      end
      
      @schema = @collection.schema.new(params[:schema])
      @schema.position = @collection.schema.count if @schema.position.blank?
      if @schema.associated_schema_id  
        @schema.type = Yogo::Collection::Property::Text #because JSON need to go here and it could get big
      end
      if @schema.save
        @schema.update_position
        if @schema.type == Yogo::Collection::Property::String || @schema.type == Yogo::Collection::Property::Text
          #lets have the table create
          @collection.items.new
          sql="ALTER TABLE #{'"'+@collection.id.to_s.gsub('-','_')+'s"'} ADD COLUMN field_#{@schema.id.to_s.gsub('-','_')}_search_index tsvector;"
          repository.adapter.execute(sql)
          sql = "UPDATE #{'"'+@collection.id.to_s.gsub('-','_')+'s"'} SET field_#{@schema.id.to_s.gsub('-','_')}_search_index = to_tsvector('english', coalesce(field_#{@schema.id.to_s.gsub('-','_')},''));"
          repository.adapter.execute(sql)
          sql = "CREATE TRIGGER field_#{@schema.id.to_s.gsub('-','_')} BEFORE INSERT OR UPDATE ON #{'"'+@collection.id.to_s.gsub('-','_')+'s"'} FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger(field_#{@schema.id.to_s.gsub('-','_')}_search_index, 'pg_catalog.english', field_#{@schema.id.to_s.gsub('-','_')});"
          repository.adapter.execute(sql)
        end
        flash[:notice] = "Schema saved successfully!"
      else
        flash[:error] = "Schema failed to save! (#{@schema.errors.full_messages.join(', ')})"
      end
      redirect_to project_collection_path(@project,@collection)
    end
    
    private
    
    def get_dependencies
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.data_collections.get(params[:collection_id])      
    end
end
