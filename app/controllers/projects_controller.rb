class ProjectsController < ApplicationController

    def index
      @projects = Yogo::Project.all
    end

    def show
      @project = Yogo::Project.get(params[:id])
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
end
