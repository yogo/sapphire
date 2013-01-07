class ProjectsController < ApplicationController
    before_filter :verify_project, :only =>[:show, :edit, :update, :upload, :process_upload, :search, :search_results]
    
    def index
        @projects = current_user.memberships.projects
        @public_projects = Yogo::Project.all(:private => false) - current_user.memberships.projects
    end

    def show
      @project = Yogo::Project.get(params[:id])
      @cv_collections = @project.data_collections(:category => "Controlled Vocabulary")
      @collections = @project.data_collections(:category =>"")
      @file_collection = @project.data_collections(:category =>"Files")
    end

    def edit
      @project = Yogo::Project.get(params[:id])
    end

    def update
      @project = Yogo::Project.get(params[:id])
      if @project.update(params[:yogo_project])
        flash[:notice] = "Project updated!"
      else
        flash[:error] = "Project failed to save! Errors: " + @project.errors.full_messages.join(', ')

      end
      redirect_to :back
    end
    
    def new
    end
    
    def create
      @project = Yogo::Project.new(params[:yogo_project])
      if @project.save
        current_user.memberships.create(:project_id => @project.id)
        @collection = @project.data_collections.new(:name => "Files", :category=>"Files")
        @collection.type = Yogo::Collection::Asset
        @collection.save
        flash[:notice] = 'New Project created!'
        redirect_to project_path(@project)
      else
        flash[:error] = "Project failed to save! Errors: " + @project.errors.full_messages.join(', ')
        redirect_to :back
      end
    end
    
    def destroy
      #@project = Yogo::Project.get(params[:id])
      #dtime = Time.now
      #@project.data_collections.each do |c|
      #  c.deleted_at = dtime
      #  c.save
      #end
      #@project.deleted_at = dtime
      #if @project.save
      # flash[:notice] = "Project was Deleted."
      #  redirect_to projects_path()
      #else
      #  flash[:error] = "Project failed to Delete" + @project.errors.inspect
        flash[:error] = "Project deletion is currently disabled.  We apoligize for the inconvience and will address this soon."
        redirect_to projects_path()
      #end
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
    
    #remove a user from a project
    def remove_user
      @project = Yogo::Project.get(params[:project_id])
      @user = User.get(params[:user_id].to_i)
      if @user.memberships.first(:project_id=> @project.id).destroy
        flash[:notice] = "#{@user.first_name} #{@user.last_name} has been removed from this project."
      else
        flash[:error] = "Failed to add user! Errors: " + @user.errors.full_messages.join(', ')
      end
      redirect_to :back
    end
    
    def associate_user
      @project = Yogo::Project.get(params[:project_id])
      @user = User.get(params[:add_user][:user_id].to_i) if params[:add_user]
      if @user && @user.memberships.first_or_create(:project_id=> @project.id)
        flash[:notice] = "#{@user.first_name} #{@user.last_name} has been add to this project."
      else
        flash[:error] = "Failed to add user! Errors: " + @user.errors.full_messages.join(', ')
      end
      redirect_to :back
    end
    
    private
    
    def insert_nonfile_item_into_collection(file, collection)
      # insert items into data_collection
      CSV.read(file, :headers => true).each do |row|
        item = collection.items.new
        collection.schema.each do |col|
          item[col.to_s] = row[col.name].blank? ? nil : row[col.name]
        end
        item.save
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
