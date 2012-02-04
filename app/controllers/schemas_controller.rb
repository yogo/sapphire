class CollectionsController < ApplicationController
    before_filter :get_dependencies

    def index
      @schemas = @collection.schema
    end

    def show
      @schema = @collection.schema.get(params[:id])
    end

    def edit
      @schema = @collection.schema.get(params[:id])
    end

    def update
      @schema = @collection.schema.get(params[:id])
      @schema.update(params[:schema])
      if @schema.save
        # success
      else
        # fail
      end
    end
    
    def new
      @schema = @collection.schema.new
    end
    
    def create
      @schema = @collection.schema.new(params[:schema])
      if @schema.save
        redirect_to project_collection_schemas_path(@project,@collection)
      else
        flash[:error] = "Schema failed to save!"
        render :new
      end
    end
    
    private
    
    def get_dependencies
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.get(params[:collection_id])      
    end
end
