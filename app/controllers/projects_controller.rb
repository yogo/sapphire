class ProjectsController < ApplicationController

    def index
      @projects = Yogo::Project.all
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
        redirect_to projects_path
      else
        flash[:error] = "Project failed to save!"
        render :new
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
           @data_collection=@project.process_zip_file_to_new_collection(@new_file)
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
           @data_collection=@project.process_zip_file_to_new_collection(@new_file)
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
      @search_results = @project.full_text_search(params[:search][:terms])
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
    
end
