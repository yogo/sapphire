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
      @items =  @collection.items(:order => :created_at.desc).all(@filters)
    else
      @items = @collection.items(:id=>nil)
      @filters.each do |k,v|
        unless v.nil?
          @items = @items + @collection.items(:order => :created_at.desc).all(k => v)
        end
      end
    end
  end

  def edit
    @collection = @project.data_collections.get(params[:id])
  end

  def edit_cv
    @collection = @project.data_collections.get(params[:collection_id])
  end
  
  def update
    @collection = @project.data_collections.get(params[:id])
    if @collection.update(params[:yogo_collection_asset])
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
    @collection = @project.data_collections.new(params[:yogo_collection_data])
    @collection.type = Yogo::Collection::Asset
    if @collection.save
      flash[:notice] = "Collection \"#{@collection.name}\" created!"
      if @collection.category == "Controlled Vocabulary"
        #create term and description columns
        @collection.schema.create(:name=>"Term", :type=>Yogo::Collection::Property::Text, :position=>0)
        @collection.schema.create(:name=>"Description", :type=>Yogo::Collection::Property::Text, :position=>1)
      end  
    else
      flash[:error] = "Collection failed to save! Errors: " + @collection.errors.full_messages.join(', ')
    end
    redirect_to project_collection_path(@project, @collection)
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
    Zip::ZipFile.open("tmp/downloads/"+filename, Zip::ZipFile::CREATE)do |z|
      @collection.items.all(@filters).all(:original_filename.not => nil).each do |item|
          z.add(item.original_filename, "public/"+item.file.to_s)
      end
      csv_string = create_collection_csv_string(@collection,@filters, true)
      new_file = "tmp/downloads/#{@collection.name}.csv"
      File.open(new_file, "wb"){ |f| f.write(csv_string)}
      z.add("#{@collection.name}.csv",new_file)
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
    name_array = collection.schema.map(&:name)
    field_array = collection.schema.map(&:to_s)
    if file == true
      name_array << "File"
      field_array << :original_filename
    end
    csv_string = CSV.generate do |csv|
      csv << name_array
      collection.items.all(conditions).all(:fields=>field_array).each do |item|
        csv << name_array.map{|n| n == "File" ? item.original_filename : item[n].to_s}
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
