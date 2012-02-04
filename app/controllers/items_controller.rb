class ItemsController < ApplicationController

    def index
      @collections = Yogo::Collection::Asset.all
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
      @collection =@project.data_collections.get(params[:collection_id])
      @item = @collection.items.new
    end
    
    def create
      collection = Yogo::Collection::Asset.get(params[:collection_id])
      if params[:item][:file]
        attrs = params[:item]
        file = attrs.delete(:file)
        @item = collection.items.new(attrs)
        @item.file.store!(file)
      else
        @item = collection.items.new(params[:item])
      end
      if @item.save
        flash[:notice] = "Item Saved!"
        redirect_to new_project_collection_items_path
      else
        flash[:error] = "Item failed to save!"
        render :new
      end
    end
end
