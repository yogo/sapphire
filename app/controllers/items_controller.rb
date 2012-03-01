class ItemsController < ApplicationController
  before_filter :get_dependencies, :except => :controlled_vocabulary_term
  layout :choose_layout
  
  def choose_layout
    if action_name == 'controlled_vocabulary_term'
      return 'controlled_vocabulary'
    else
      return 'application'
    end
  end
  def index
    if params[:item]
      @item = @collection.items.new(params[:item])
    else
      @item =@collection.items.new()
    end 
    @schema_cv_hash={}
    @collection.schema.each do |s|
      link_hash={}
      if s.controlled_vocabulary_id
        @schema_cv_hash[s.id] = Yogo::Collection::Property.get(s.controlled_vocabulary_id).data_collection
        s.data_collection.items.each do |i|
          link_hash = link_hash.merge({i[s.name] => @schema_cv_hash[s.id].items.first("field_#{s.controlled_vocabulary_id.to_s.gsub('-','_')}".to_sym=>i[s.name])})
        end
        @schema_cv_hash[s.name]=link_hash
      end
    end
  end
  
  def controlled_vocabulary_term
    @item = @collection.items.get(params[:item_id])
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
  
  def destroy
    @item = @collection.items.get(params[:id])
    if @item.destroy
      flash[:notice] = "Item was Deleted."
      redirect_to project_collection_items_path(@project, @collection)
    else
      flash[:error] = "Item failed to Delete"
      render :index
    end
  end
  
  def export
    @item = @collection.items.get(params[:id])
    filename ="#{@collection.name}.csv"
    send_data(@items.to_csv,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => filename)
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
    if !current_user.memberships(:project_id => params[:project_id]).empty? || Yogo::Project.get(params[:project_id]).private == false || Yogo::Collection::Data.get(params[:collection_id]).private == false
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.data_collections.get(params[:collection_id])
    else
      flash[:error] = "You don't have access to that project!"
      redirect_to projects_path()
      return
    end 
  end
end
