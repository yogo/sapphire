class CollectionsController < ApplicationController
    before_filter :get_project

    def index
      @collections = @project.data_collections
    end

    def show
      @collection = @project.data_collections.get(params[:id])
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

    def edit
      @collection = @project.data_collections.get(params[:id])
    end

    def update
      @collection = @project.data_collections.get(params[:id])
      if @collection.update(params[:collection])
        flash[:notice] = "Collection updated!"
        redirect_to project_collection_path(@project,@collection)
      else
        flash[:error] = "Collection failed to update!"
        render edit
      end
    end
    
    def new
      @collection = @project.data_collections.new
    end
    
    def create
      @collection = @project.data_collections.new(params[:collection])
      @collection.project = @project
      @collection.type = Yogo::Collection::Asset
      if @collection.save
        flash[:notice] = "Collection created!"
        redirect_to project_path(@project)
      else
        flash[:error] = "Collection failed to save!"
      end
    end
    
    def destroy
      @collection = @project.data_collections.get(params[:id])
      @collection.items.destroy
      @collection.schema.destroy
      if @collection.destroy
       flash[:notice] = "Collection was Deleted."
        redirect_to project_path(@project)
      else
        flash[:error] = "Collection failed to Delete"+@collection.errors.inspect
        redirect_to project_path(@project)
      end
    end
    def upload
      render 'projects/upload'
    end
    
    private
    
    def get_project
      if current_user.memberships(:project_id => params[:project_id]).empty?
        flash[:error] = "You don't have access to that project!"
        redirect_to projects_path()
        return
      else
        return @project = Yogo::Project.get(params[:project_id])
      end
    end
end
