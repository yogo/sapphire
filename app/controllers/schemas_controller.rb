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
      if params[:schema][:controlled_vocabulary_id].blank?
        params[:schema][:controlled_vocabulary_id] = nil
      end
      if params[:schema][:associated_schema_id].blank?
        params[:schema].delete(:associated_schema_id)
      elsif @schema.associated_schema_id !=params[:schema][:associated_schema_id]
        @schema.deleted_at = Time.now
        @schema.save
        @schema = @collection.schema.create(params[:schema])
        redirect_to project_collection_path(@project,@collection)
      else
        if @schema.update(params[:schema])
          # success
          redirect_to project_collection_path(@project,@collection)
        else
          # fail
          render :edit
        end
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
      if @schema.save
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
        #redirect_to project_collection_path(@project,@collection)
        flash[:notice] = "Schema saved successfully!"
        redirect_to :back
      else
        flash[:error] = "Schema failed to save!"
      end

    end
    
    private
    
    def get_dependencies
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.data_collections.get(params[:collection_id])      
    end
end
