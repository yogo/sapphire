class ItemsController < ApplicationController
  before_filter :get_dependencies

  def index
    if params[:item]
      @item = @collection.items.new(params[:item])
    else
      @item =@collection.items.new()
    end 
  end
  
  #expects the delete_at datetime in params[:deleted_at]
  def restore
     @item = @collection.items.get(params[:item_id])
     old_item = @item.versions.first(:deleted_at => params[:deleted_at])
     att = old_item.attributes
     att.delete(:deleted_at)
     att.delete(:original_uid)
     att.delete(:id)
     if @item.update(att)
       flash[:notice] = "Item Restored Successfully!"
       redirect_to project_collection_item_path(@project, @collection, @item)
     else
       flash[:error] = "Item failed to restore!"
       render :show
     end
  end
  
  def update
    @item = @collection.items.get(params[:id])
    if @item.update(params[:item])
      flash[:notice] = "Item Updated Successfully!"
      redirect_to project_collection_items_path(@project, @collection)
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
    @collection.schema.each do |field|
      if @item[field.name].blank?
        @item[field.name]=nil
      end
    end
    if @item.save
      flash[:notice] = "Item Saved!"
      redirect_to project_collection_items_path(@project, @collection)
    else
      flash[:error] = "Item failed to save: #{@item.errors.to_hash.map{|h| Yogo::Collection::Property.get(h.to_s.split(',')[0].gsub("[:field_",'').gsub('_','-')).name + h.to_s.split(',')[1].gsub(h.to_s.split(',')[0].gsub("field_",'Field ').gsub('_',' '),'')}.join(', ')}"
      
      #+ h.split(',')[1][0].gsub(h.to_s.split(',')[0].gsub("field_",'Field ').gsub('_',' '),'')
      render :index
    end
  end
  
  private
  
  def get_dependencies
    @project = Yogo::Project.get(params[:project_id])
    @collection = @project.data_collections.get(params[:collection_id])      
  end
end
