class ItemsController < ApplicationController
  before_filter :get_dependencies

  def index
  end
  
  def update
    @item = @collection.items.get(params[:id])
    if @item.update(params[:item])
      flash[:notice] = "Item Updated Succesfully!"
      redirect_to project_collection_item_path(@project, @collection, @item)
    else
      flash[:error] = "Item failed to save!"
      render :edit
    end
  end
  def show
    @item = @collection.items.get(params[:id])
  end

  def edit
    @item = @collection.items.get(params[:id])
  end

  
  def new
  end
  
  def create
    @item = @collection.items.new(params[:item])
    if @item.save
      flash[:notice] = "Item Saved!"
      redirect_to project_collection_items_path(@project, @collection)
    else
      flash[:error] = "Item failed to save!"
      render :index
    end
  end
  
  private
  
  def get_dependencies
    @project = Yogo::Project.get(params[:project_id])
    @collection = @project.data_collections.get(params[:collection_id])      
  end
end
