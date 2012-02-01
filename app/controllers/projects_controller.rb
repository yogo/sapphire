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
end
