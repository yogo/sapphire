class ItemsController < ApplicationController

  before_filter :get_dependencies, :except => :controlled_vocabulary_term
  after_filter :update_project_stats, :only => [:create, :delete]
  #after_filter :update_associated_fields, :only =>[:update]
  layout :choose_layout
  

  def index
    if params[:item]
      @item = @collection.items.new(params[:item])
    else
      @item =@collection.items.new()
    end 
  end
  
  def controlled_vocabulary_term
    @project = Yogo::Project.get(params[:project_id])
    @collection = @project.data_collections.get(params[:collection_id])
    @item = @collection.items.get(params[:item_id])
    #@item = @collection.items.first(:params[:cv])
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
      update_associated_fields(@item, @collection, @project)
      respond_to do |format|
        format.html do
          flash[:notice] = "Item Updated Successfully!"
          redirect_to project_collection_path(@project, @collection)   
        end
        #format.json { render json: @item.to_json, status: :updated}
        format.js { render :js => '$("#message").html("<h2>Item updated. Close window and refresh your page.</h2>").attr("class","message notice"); $("html, body").animate({scrollTop: "0px"})' }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = "Item failed to save!"
          render :edit
        end
        format.json { render json: @item.to_json, status: :error}
        format.js { render :js => '$("#message").html("<h2>Item failed updated.</h2>").attr("class","message error").scrollTop(0); $("html, body").animate({scrollTop: "0px"})' }
      end
    end
  end
  
  def show
    @item = @collection.items.get(params[:id])
  end

  def edit
    @item = @collection.items.get(params[:id])
  end

  def association_edit
    @item = @collection.items.get(params[:item_id])
  end
  
  def new
  end
  
  def destroy
    @item = @collection.items.get(params[:id])
    if @item.destroy
      flash[:notice] = "Item was Deleted."
      redirect_to project_collection_path(@project, @collection)
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
      redirect_to :back
      #redirect_to project_collection_items_path(@project, @collection)
    else
      flash[:error] = "Item failed to save: #{@item.errors.to_hash.map{|h| Yogo::Collection::Property.get(h.to_s.split(',')[0].gsub("[:field_",'').gsub('_','-')).name + h.to_s.split(',')[1].gsub(h.to_s.split(',')[0].gsub("field_",'Field ').gsub('_',' '),'')}.join(', ')}"
      
      #+ h.split(',')[1][0].gsub(h.to_s.split(',')[0].gsub("field_",'Field ').gsub('_',' '),'')
      redirect_to :back
      #render :back
    end
  end
  
  private
  def choose_layout
    case action_name
    when 'controlled_vocabulary_term', 'show', 'association_edit'
      'blank'
    else
      'application'
    end
  end
  
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
  
  def update_project_stats
    @project.update_stats
  end
  
  def update_associated_fields(item, collection, project)
    collection.schema.all.each do |schema|
      associated_columns = Yogo::Project.all.data_collections.schemas.all(:associated_schema_id=>schema.id)
      associated_columns.each do |col|
        field_name = "field_"+col.id.to_s.gsub("-","_")
        col.data_collection.items.all(field_name.to_sym.like => '%{"project":{"id": "'+project.id+'"}, "collection":{"id": "'+collection.id+'"},"item":{"id": "'+item.id.to_s+'",%').each do |i|
          i[col.name] = '{"project":{"id": "'+project.id+'"}, "collection":{"id": "'+collection.id+'"},"item":{"id": "'+item.id.to_s+'", "display": "'+item[schema.name]+'"}}'
          i.save
        end
      end
    end
  end
end
