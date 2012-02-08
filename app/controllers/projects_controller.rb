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
      #specify create or load into existing
    end
    
    def process_upload
      # if new data collectin
      if params[:upload][:collection].nil?
         # create/update data_collection schema
      else# if existing data collectin
        #update schema
      end
      
      # insert items into data_collection
      
      # redirect to data collection index
    end
end
