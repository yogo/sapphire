class ProjectsController < ApplicationController
    before_filter :verify_project, :only =>[:show, :edit, :update, :upload, :process_upload, :search, :search_results]
    
    def index
      @projects = Yogo::Project.all(:id=>current_user.memberships.map{|m| m.project_id})
    end

    def show
      @project = Yogo::Project.get(params[:id])
      @collections = @project.data_collections
    end

    def edit
      @project = Yogo::Project.get(params[:id])
    end

    def update
      @project = Yogo::Project.get(params[:id])
      @project.merge(params[:project])
    end
    
    def new
      @project = Yogo::Project.new
    end
    
    def create
      @project = Yogo::Project.new(params[:yogo_project])
      if @project.save
        current_user.memberships.create(:project_id => @project.id)
        redirect_to projects_path
      else
        flash[:error] = "Project failed to save!"
        render :new
      end
    end
    
    def destroy
      @project = Yogo::Project.get(params[:id])
      if @project.destroy
       flash[:notice] = "Project was Deleted."
        redirect_to projects_path()
      else
        flash[:error] = "Project failed to Delete"
        render :index
      end
    end
    
    def upload
     @project = Yogo::Project.get(params[:project_id])
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
      @users = User.all.map{|u| ["#{u.last_name}, #{u.first_name}",u.id] }
      @current_project_users = User.all(:id => Membership.all(:project_id=> @project.id).map{|m| m.user_id})
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
        item.save
      end
    end
    
    def verify_project
      if current_user.memberships(:project_id => params[:id]).empty? && current_user.memberships(:project_id => params[:project_id]).empty?
        flash[:error] = "You don't have access to that Project!"
        redirect_to projects_path()
      end
    end
    
end
