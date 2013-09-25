class ItemsController < ApplicationController
  before_filter :get_filters
  before_filter :get_dependencies
  after_filter :update_project_stats, :only => [:create, :delete]

  def index
    @r={}
    if params[:item]
      @item = @collection.items.new(params[:item])
    else
      @item =@collection.items.new()
    end 
    respond_to do |format|
      format.html {render :index}
      format.json {
        if @collection.items.all(:conditions=>@filters).count > 0
            render :json => DataMapper.raw_select(@collection.items.all(:conditions=>@filters).all(:fields=>@collection.schema(:order=>[:position]).map{|a| a.field_name}.unshift(:id))).sql_to_datatable_json
        else
          data={}
          data[:aaData] = Array.new()
          data[:sEcho] = 1
          data[:iTotalRecords] = 0
          data[:iTotalDisplayRecords] = 0
          render :json => data.to_json
        end
      }

      format.csv {
        request.env['HTTP_ACCEPT_ENCODING'] = 'gzip'
        render :text =>  DataMapper.raw_select(@collection.items).sql_to_csv
      }
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
  
  # TODO: move the nullification of the fields into a before :save
  def update
    @item = @collection.items.get(params[:id])
    @collection.schema.each do |field|
      if params[:item][field.to_s].blank? && !field.is_file
        @item[field.name]=nil
      elsif field.is_file
        #do nothing
        unless params[:item][field.to_s].nil?
          new_file = @file_collection.items.new()
          new_file.file =params[:item][field.to_s]
          new_file.save
          @item[field.name]='{"project":{"id": "'+@project.id+'"}, "collection":{"id": "'+@file_collection.id+'"},"item":{"id": "'+new_file.id.to_s+'", "display": "'+new_file.original_filename+'"}}'
        end
      else
        @item[field.name] = params[:item][field.to_s]
      end
    end
    if @item.save
      update_associated_fields(@item, @collection, @project)
      respond_to do |format|
        format.html do
          flash[:notice] = "Item Updated Successfully!"
        end
        #format.json { render json: @item.to_json, status: :updated}
        format.js { render :js => '$("#message").html("<h2>Item updated. Close window and refresh your page.</h2>").attr("class","message notice"); $("html, body").animate({scrollTop: "0px"})' }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = ["Item failed to save! Errors:", @item.errors.full_messages].flatten.join(' ')
        end
        format.json { render json: @item.to_json, status: :error}
        format.js { render :js => '$("#message").html("<h2>Item failed update.</h2>").attr("class","message error").scrollTop(0); $("html, body").animate({scrollTop: "0px"})' }
      end
    end
    redirect_to :back
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
      elsif field.is_file
        new_file = @file_collection.items.new()
        new_file.file =params[:item][field.to_s]
        new_file.save
        @item[field.name]='{"project":{"id": "'+@project.id+'"}, "collection":{"id": "'+@file_collection.id+'"},"item":{"id": "'+new_file.id.to_s+'", "display": "'+new_file.original_filename+'"}}'
      end
    end
    if @item.save
      flash[:notice] = "Item Saved!"
      respond_to do |format|
        format.html {redirect_to :back}
        format.json {render :json => @item.to_json}
      end
      #redirect_to project_collection_items_path(@project, @collection)
    else
      flash[:error] = "Item failed to save: #{@item.errors.to_hash.map{|h| Yogo::Collection::Property.get(h.to_s.split(',')[0].gsub("[:field_",'').gsub('_','-')).name + h.to_s.split(',')[1].gsub(h.to_s.split(',')[0].gsub("field_",'Field ').gsub('_',' '),'')}.join(', ')}"
      
      #+ h.split(',')[1][0].gsub(h.to_s.split(',')[0].gsub("field_",'Field ').gsub('_',' '),'')
      respond_to do |format|
        format.html {redirect_to :back}
        format.json {render :json => {:error=>flash[:error]}.to_json}
      end
    end
  end
  
  def datatable
    @objects = current_objects(params)
    @total_objects = total_objects(params)
    render :layout => false
  end
  
  private
  
  def current_objects(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0)+1
    @current_objects = Object.paginate :page => current_page, 
                                       :include => [:item], 
                                       :order => "#{datatable_columns(params[:iSortCol_0])} #{params[:sSortDir_0] || "DESC"}", 
                                       :conditions => conditions,
                                       :per_page => params[:iDisplayLength]
  end
  
  def total_objects(params={})
    @total_objects = Object.count :include => [:item], :conditions => conditions
  end

  def datatable_columns(column_id)
    case column_id.to_i
    when 1
      return "objects.description"
    when 2
      return "objects.created_at"
    else
      return "items.id"
    end
  end

  def conditions
    conditions = []
    conditions << "(objects.description ILIKE '%#{params[:sSearch]}%' OR items.id ILIKE '%#{params[:sSearch]}%')" if(params[:sSearch])
    return conditions.join(" AND ")
  end
  
  def get_dependencies
    if !current_user.memberships(:project_id => params[:project_id]).empty? || Yogo::Project.get(params[:project_id]).private == false || Yogo::Collection::Data.get(params[:collection_id]).private == false
      @project = Yogo::Project.get(params[:project_id])
      @collection = @project.data_collections.get(params[:collection_id])
      @file_collection = @project.data_collections.first(:category=>"Files")
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
  
  def get_filters
     @filters = {}
     if params[:field] && !params[:field].empty?
       params[:field].each_with_index do |val, index|
         next if val.blank?  #skip blank values
         unless params[:predicate][index].empty? || params[:value][index].empty?
          case params[:predicate][index]
          when "="
            @filters[val.to_sym] = "#{params[:value][index]}"
          when "not"
            @filters[val.to_sym.not] = "#{params[:value][index]}"
          when "like"
            @filters[val.to_sym.like] = "#{params[:value][index]}%"
          when "gt"
            @filters[val.to_sym.gt] = "#{params[:value][index]}"
          when "gte"
            @filters[val.to_sym.gte] = "#{params[:value][index]}"
          when "lt"
            @filters[val.to_sym.lt] = "#{params[:value][index]}"
          when "lte"
            @filters[val.to_sym.lte] = "#{params[:value][index]}"
          end
         end
       end
     end
   end
   
   def get_filters2
      @filter_array = []
      if params[:field] && !params[:field].empty?
        params[:field].each_with_index do |val, index|
          next if val.blank?  #skip blank values
          unless params[:predicate][index].empty? || params[:value][index].empty?
           @filters = {}
           case params[:predicate][index]
           when "="
             @filter_array << ['\''+val + ' = ?\'', params[:value][index]]
             #@filters[val.to_sym] = "#{params[:value][index]}"
           when "not"
             @filters[val.to_sym.not] = "#{params[:value][index]}"
           when "like"
             @filters[val.to_sym.like] = "#{params[:value][index]}%"
           when "gt"
             @filters[val.to_sym.gt] = "#{params[:value][index]}"
           when "gte"
             @filters[val.to_sym.gte] = "#{params[:value][index]}"
           when "lt"
             @filters[val.to_sym.lt] = "#{params[:value][index]}"
           when "lte"
             @filters[val.to_sym.lte] = "#{params[:value][index]}"
           end
           #@filter_array << @filters
          end
        end
      end
    end
end
