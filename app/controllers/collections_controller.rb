class CollectionsController < ApplicationController
    before_filter :get_project

    def index
      @collections = @project.data_collections
    end

    def show
      @collection = Yogo::Collection::Data.get(params[:id])
    end

    def edit
      @collection = Yogo::Collection::Data.get(params[:id])
    end

    def update
      @collection = Yogo::Collection::Data.get(params[:id])
      @collection.merge(params[:collection])
    end
    
    def new
      @collection = Yogo::Collection::Asset.new
    end
    
    def create
      @collection = Yogo::Collection::Asset.new(params[:yogo_collection_asset])
      @collection.project = @project
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
