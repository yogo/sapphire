class ProjectsController < ApplicationController
    before_filter :verify_project, :only =>[:show, :edit, :update, :upload, :process_upload, :search, :search_results]
    
    def index
      if params[:public]
        my_projects = current_user.memberships.projects
        @projects = Yogo::Project.all(:private => false) - my_projects
        @collections = Yogo::Collection::Data.all(:private=>false) - my_projects.data_collections
        @nav_public_project = true
      else
        @projects = current_user.memberships.projects
        @nav_my_project = true
      end
    end

    def show
      @project = Yogo::Project.get(params[:id])
      @collections = @project.data_collections(:category.not => ["Schema Controlled Vocabulary","Controlled Vocabulary"])
      @cv_collections = @project.data_collections(:category => "Controlled Vocabulary")
      @scv_collections =@project.data_collections(:category => "Schema Controlled Vocabulary")
    end

    def edit
      @project = Yogo::Project.get(params[:id])
    end

    def update
      @project = Yogo::Project.get(params[:id])
      if @project.update(params[:yogo_project])
        flash[:notice] = "Project updated!"
        redirect_to project_path(@project)
      else
        flash[:error] = "Project failed to save!"
        render :new
      end
    end
    
    def new
      @project = Yogo::Project.new
    end
    
    def create
      @project = Yogo::Project.new(params[:yogo_project])
      if @project.save
        current_user.memberships.create(:project_id => @project.id)
        redirect_to project_path(@project)
      else
        flash[:error] = "Project failed to save!"
        render :new
      end
    end
    
    def destroy
      @project = Yogo::Project.get(params[:id])
      dtime = Time.now
      @project.data_collections.each do |c|
        c.deleted_at = dtime
        c.save
      end
      @project.deleted_at = dtime
      if @project.save
       flash[:notice] = "Project was Deleted."
        redirect_to projects_path()
      else
        flash[:error] = "Project failed to Delete" + @project.errors.inspect
        redirect_to projects_path()
      end
    end
    
    def manage_controlled_vocabularies
      project_ids= current_user.memberships(:fields=>[:project_id]).map{|m| m.project_id}.uniq
      @collections = Yogo::Collection::Data.all(:project_id=> project_ids, :category=>"Controlled Vocabulary")
      public_project_ids = Yogo::Project.all(:private=>false).map{|p| p.id} - project_ids
      public_collection_ids = Yogo::Collection::Data.all(:project_id=> public_project_ids, :category=>"Controlled Vocabulary").map{|c| c.id}
      public_collection_ids = (public_collection_ids + Yogo::Collection::Data.all(:private=>false, :category=>"Controlled Vocabulary").map{|c| c.id}).uniq
      public_collection_ids = public_collection_ids - @collections.map{|c| c.id}
      @public_collections = Yogo::Collection::Data.all(:id => public_collection_ids)
   
      @nav_controlled_vocabulary = true # light up the "controlled vocabulary nav"
    end
    
    def upload
     @project = Yogo::Project.get(params[:project_id])
    end
    
    #use this API to publish or unpublish
    #this essentially toggles the private field
    def publish
      verify_membership
      @project = Yogo::Project.get(params[:project_id])
      @project.private = @project.private == true ? false : true
      if @project.save
        flash[:notice] = "Project successfully changed publicaction status."
        redirect_to project_path(@project)
      else
        flash[:error] = "Project failed to change publication status!"
        render :index
      end
    end
    
    def process_upload
      @project = Yogo::Project.get(params[:project_id])
      @new_file = "temp_data/"+Time.now.to_i.to_s + params[:upload][:file].original_filename 
      File.open(@new_file, "wb"){ |f| f.write(params[:upload][:file].read)}
      # if new data collection
      if params[:upload][:collection].empty?
         #check if file is a zip file
         if @new_file.include?(".zip")
           @data_collection=@project.process_zip_file_to_collection(@new_file,params[:upload][:file].original_filename)
         else
           # create/update data_collection schema
           @data_collection= @project.collection_from_file(params[:upload][:file].original_filename, @new_file)
           # insert items into data_collection
           insert_nonfile_item_into_collection(@new_file, @data_collection)
         end
      else# if existing data collectin
        #TODO update schema?
        #fetch schema
        if @new_file.include?(".zip")
           @data_collection=@project.process_zip_file_to_collection(@new_file,params[:upload][:file].original_filename, @data_collection)
        else
          @data_collection =  @project.data_collections.get(params[:upload][:collection])
          #if there are new field update the collection
          @data_collection= @project.collection_from_file(params[:upload][:file].original_filename, @new_file, @data_collection)
          # insert items into data_collection
          insert_nonfile_item_into_collection(@new_file, @data_collection)
        end
      end
      
      # redirect to data collection index
      redirect_to project_collection_path(@project.id, @data_collection.id)
    end
    
    
    def search
      @project = Yogo::Project.get(params[:project_id])
    end
    
    def search_results
      @project = Yogo::Project.get(params[:project_id])
      @data_collections = @project.data_collections
      @search_results = @project.full_text_search(params[:search][:terms].downcase)
      @schema_cv_hash={}
      collections = @project.data_collections.all(:id=>@search_results.keys)
      collections.each do |coll|
        coll.schema.each do |s|
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
    end
    
    def add_user
      @project = Yogo::Project.get(params[:project_id])
    end
    
    def associate_user
      @project = Yogo::Project.get(params[:project_id])
      @user = User.get(params[:add_user][:user_id].to_i)
      if @user.memberships.first_or_create(:project_id=> @project.id)
        flash[:notice] = "#{@user.first_name} #{@user.last_name} has been add to this project."
        redirect_to project_path(@project)
      else
        flash[:error] = "Failed to add user!"
        render :add_user
      end
    end
    
    private
    
    def insert_nonfile_item_into_collection(file, collection)
      # insert items into data_collection
      #read header row
      csv = CSV.read(file)
      header_row = csv[0]
      (1..csv.length-1).each do |j|
        item = collection.items.new
        i=0
        header_row.map{|h| item[h]=csv[j][i]; i+=1}
        collection.schema.each do |field|
          if item[field.name].blank?
            item[field.name]=nil
          end
        end
        item.save
        #if item.versions.empty?
        #  item.make_version
        #end
      end
    end
    
    def verify_project
      if !Yogo::Project.get(params[:id]).nil? 
        if Yogo::Project.get(params[:id]).private
          #project is private so you need to be a member
          verify_membership
        end
      elsif !Yogo::Project.get(params[:project_id]).nil?
        if Yogo::Project.get(params[:project_id]).private 
          #project is private so you need to be a member
          verify_membership
        end
      end
      #if we are here the project is public so proceed
    end
    
    def verify_membership
      if current_user.memberships(:project_id => params[:id]).empty? && current_user.memberships(:project_id => params[:project_id]).empty?
        #you aren't a member so go back
        flash[:error] = "You don't have access to that Project!"
        redirect_to projects_path()
      end
      #you are member proceed
    end
end
