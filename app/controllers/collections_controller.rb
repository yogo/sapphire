class CollectionsController < ApplicationController
    before_filter :get_project

    def index
      @collections = @project.data_collections
    end

    def show
      @collection = @project.data_collections.get(params[:id])
    end

    def edit
      @collection = @project.data_collections.get(params[:id])
    end

    def update
      @collection = @project.data_collections.get(params[:id])
      @collection.merge(params[:collection])
    end
    
    def new
      @collection = @project.data_collections.new
    end
    
    def create
      @collection = @project.data_collections.new(params[:yogo_collection_asset])
      @collection.project = @project
      @collection.type = Yogo::Collection::Asset
      if @collection.save
        redirect_to project_collections_path(@project)
      else
        flash[:error] = "Collection failed to save!"
        render :new
      end
    end
    
    private
    
    def get_project
      @project = Yogo::Project.get(params[:project_id])
    end
end
