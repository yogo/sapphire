class CollectionsController < ApplicationController
  before_filter :get_project
  before_filter :get_filters

  def index
    @collections = @project.data_collections
  end

  def show
    @collection = @project.data_collections.get(params[:id])
    @item = @collection.items.new(params[:item])
    @filter_item = @collection.items.new
    if params[:options] == "AND" || params[:options].nil? || @filters.empty?
      @items =  @collection.items.all(@filters)
    else
      @items = @collection.items(:id=>nil)
      @filters.each do |k,v|
        unless v.nil?
          @items = @items + @collection.items.all(k => v)
        end
      end
    end
    
    @items_raw = @items
  end

  def edit
    @collection = @project.data_collections.get(params[:id])
  end

  def edit_cv
    @collection = @project.data_collections.get(params[:collection_id])
  end
  
  def update
    @collection = @project.data_collections.get(params[:id])
    if @collection.update(params[:collection])
      flash[:notice] = "Collection updated!"
    else
      flash[:error] = "Collection failed to update! Errors: " + @collection.errors.full_messages.join(', ')
    end
    redirect_to project_collection_path(@project, @collection)
  end
  
  def new
    @collection = @project.data_collections.new
  end
  
  def create
    @collection = @project.data_collections.new(params[:collection])
    @collection.type = Yogo::Collection::Data
    if @collection.save
      flash[:notice] = "Collection \"#{@collection.name}\" created!"
      if @collection.category == "Controlled Vocabulary"
        #create term and description columns
        @collection.schema.create(:name=>"Term", :type=>Yogo::Collection::Property::String, :position=>0)
        @collection.schema.create(:name=>"Description", :type=>Yogo::Collection::Property::Text, :position=>1)
      end  
      redirect_to project_collection_path(@project, @collection)
    else
      flash[:error] = "Collection failed to save! Errors: " + @collection.errors.full_messages.join(', ')
      redirect_to :back
    end
  end
  
  def destroy
    @collection = @project.data_collections.get(params[:id])
    @collection.deleted_at = Time.now
    if @collection.save
     flash[:notice] = "Collection was Deleted."
      redirect_to project_path(@project)
    else
      flash[:error] = "Collection failed to Delete! Errors: " + @collection.errors.full_messages.join(', ')
      redirect_to project_path(@project)
    end
  end
  
  #use this API to publish or unpublish
  #this essentially toggles the private field
  def publish
    unless current_user.memberships(:project_id => params[:project_id]).empty?
      @collection = @project.data_collections.get(params[:collection_id])
      @collection.private = @collection.private == true ? false : true
      if @collection.save
        flash[:notice] = "Collection successfully changed publicaction status."
        redirect_to project_collection_path(@project,@collection)
      else
        flash[:error] = "Collection failed to change publication status! Errors: " + @collection.errors.full_messages.join(', ')
        render :index
      end
    else
      flash[:error] = "You don't have permission to change publication status!"
      render :index
    end
  end
  
  def export
    @collection = @project.data_collections.get(params[:collection_id])
    filename ="#{@collection.name}.csv"
    csv_string = create_collection_csv_string(@collection, @filters)      
    send_data(csv_string,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => filename)
  end
  
  def export_with_files
    require 'zip/zip'
    @collection = @project.data_collections.get(params[:collection_id])
    filename ="#{@collection.name}-#{Time.now.to_i}.zip"
    filename_array = []
    file_uid_array = []
    Zip::ZipFile.open("tmp/downloads/"+filename, Zip::ZipFile::CREATE) do |z|
      
      @collection.items.all.each do |item|
        
        begin
          @collection.schema.all(:is_file=>true).each do |field|

           unless item[field.name].nil?
             if   filename_array.count(@file_collection.items.get(JSON.parse(item[field.name])['item']['id']).original_filename) > 0
               if file_uid_array.count(@file_collection.items.get(JSON.parse(item[field.name])['item']['id']).file.to_s) == 0
                 base_filename = @file_collection.items.get(JSON.parse(item[field.name])['item']['id']).original_filename
                 new_filename = base_filename + "2"
                 count = 2
                 while filename_array.count(new_filename) > 0 do
                    count = count + 1
                    new_filename = base_filename + count.to_s
                 end
                 z.add(new_filename, "public/"+@file_collection.items.get(JSON.parse(item[field.name])['item']['id']).file.to_s)
                 filename_array << new_filename
                 file_uid_array << @file_collection.items.get(JSON.parse(item[field.name])['item']['id']).file.to_s
               end
             else 
               z.add(@file_collection.items.get(JSON.parse(item[field.name])['item']['id']).original_filename, "public/"+@file_collection.items.get(JSON.parse(item[field.name])['item']['id']).file.to_s)
               filename_array << @file_collection.items.get(JSON.parse(item[field.name])['item']['id']).original_filename
               file_uid_array << @file_collection.items.get(JSON.parse(item[field.name])['item']['id']).file.to_s
             end
           end
          end
        rescue Exception => e 
          puts e.message  
          #puts e.backtrace.inspect
          #z.add(item.original_filename + "_2", "public/"+item.file.to_s)
        end
      end
      csv_string = create_collection_csv_string(@collection,@filters, true)
      new_file = "tmp/downloads/#{@collection.name}_"+Time.now.to_s+".csv"
      File.open(new_file, "wb"){ |f| f.write(csv_string)}
      z.add("#{@collection.name}_"+Time.now.to_s+".csv",new_file)
      z.close()
    end
    send_file("tmp/downloads/"+filename, :type => 'application/zip')
  end
   
  def upload
    render 'projects/upload'
  end
  
  # TODO: Is this necessary?
  def cv
    @collection = @project.data_collections.get(params[:collection_id])
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

  def datatable
    collection = project.data_collections.get(params[:id])
    respond_to do |format|
      format.json { render json: ItemsDatatable.new(view_context, collection) }
    end
  end
  
  def objects
    @collection = @project.data_collections.get(params[:collection_id])
    @items = DataMapper.raw_select(@collection.items.all())
    respond_to do |format|
      format.json { render json: @items.sql_to_json }
    end
  end
  
  def associations
    schema = @project.data_collections.get(params[:collection_id]).schema.get(params[:schema_id])
    str = schema.data_collection.items.page(:page=>params[:page], :fields=>["#{schema.field_name}", :id], "#{schema.field_name}".to_sym.like=>"%#{params[:term]}%").to_json
    
    respond_to do |format|
      format.json {
        render json: JSON.parse(str).map{|i| [i[schema.field_name], '{"project":{"id": "'+@project.id+'"}, "collection":{"id": "'+schema.data_collection.id+'"},"item":{"id": "'+i['id']+'", "display": "'+(i[schema.field_name].nil? ? "" : i[schema.field_name])+'"}}'] }
      }
    end
  end
  private
  def get_project
    if !Yogo::Collection::Data.get(params[:id]).nil? 
      if Yogo::Collection::Data.get(params[:id]).private
        #project is private so you need to be a member
        verify_membership
      end
    elsif !Yogo::Collection::Data.get(params[:collection_id]).nil?
      if Yogo::Collection::Data.get(params[:collection_id]).private 
        #project is private so you need to be a member
        verify_membership
      end
    end
    #if we are here the project is public so proceed
    @project = Yogo::Project.get(params[:project_id])
    @file_collection = @project.data_collections.first(:category=>"Files")
  end
  
  def verify_membership
    if Yogo::Project.get(params[:project_id]).private
      if current_user.memberships(:project_id => params[:project_id]).empty?
        flash[:error] = "You don't have access to that project!"
        redirect_to projects_path()
        return
      end
    end
    #you are member or project is public -proceed
  end
  
  def create_collection_csv_string(collection, conditions, file=false)
    name_array = []#collection.schema.map(&:name)
    collection.schema.each do |schema|
      if schema.associated_schema 
        schema.associated_schema.data_collection.schema.each do |s| 
          name_array << schema.name+"_"+s.name
        end
        #name_array << schema.name+"_File"
      else
        name_array << schema.name
      end
    end
    #name_array << "File"
    field_array = collection.schema.map(&:to_s)
    
    # if file == true
    #   name_array << "File"
    #   field_array << :original_filename
    # end
    csv_string = CSV.generate do |csv|
      csv << name_array
      DataMapper.raw_select(collection.items.all(:fields=>collection.schema.map{|s| s.field_name}).all(conditions)).each do |item|
        row_array = []
        collection.schema.each do |s|  
          if s.associated_schema
            unless item[s.field_name].nil?
              json_string = JSON.parse(item[s.field_name])
              assoc_item = s.associated_schema.data_collection.items.get(json_string['item']['id'])
              s.associated_schema.collection.data_collection.schema.each do |assoc|
                if assoc.associated_schema
                  unless assoc_item[assoc.name].nil?
                    row_array << JSON.parse(assoc_item[assoc.name])['item']['display']
                  else
                    row_array <<""
                  end
                else
                  row_array << (assoc.name == "File" ? assoc_item.original_filename : assoc_item[assoc.name].to_s)
                end
              end
              #row_array << item.original_filename
            else
              s.associated_schema.data_collection.schema.each do |s|
                row_array << ""
              end
              row_array << ""
            end
          elsif s.is_file && !item[s.field_name].nil?
            row_array << JSON.parse(item[s.field_name])['item']['display']
          else
            row_array << (s.name == "File" ? item.original_filename : item[s.field_name].to_s)
          end
        end
        #row_array << item.original_filename
        csv << row_array
      end
    end
    csv_string
  end

  def get_filters
    @filters = {}
    if params[:filters] && !params[:filters].empty?
      params[:filters].each do |k,v|
        next if v.blank?
        @filters[k.to_sym.like] = "%#{v}%"
      end
    end
  end

end
