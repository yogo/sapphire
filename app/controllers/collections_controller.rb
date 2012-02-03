class CollectionsController < ApplicationController

    def index
      @collections = Yogo::Collection::Data.all
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
      @collection = Yogo::Collection::Data.new
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
