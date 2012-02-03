class ItemsController < ApplicationController

    def index
      @collections = Yogo::Collection::Data.all
    end

    def show
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.data_collections.get(params[:id])
    end

    def edit
      @collection = Yogo::Collection::Asset.get(params[:id])
    end

    def update
      @collection = Yogo::Collection::Asset.get(params[:id])
      @collection.merge(params[:collection])
    end
    
    def new
      @project = Yogo::Project.get(params[:project_id])
      @collection = Yogo::Collection::Data.get(params[:collection_id])
      @items =@collection.items.new
    end
    
    def create
      @collection = Yogo::Collection::Data.new(params[:yogo_collection])
      if @collection.save
        redirect_to collections_path
      else
        flash[:error] = "CollectionData failed to save!"
        render :new
      end
    end
end
