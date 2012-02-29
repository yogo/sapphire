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
          flash[:error] = "Collection failed to change publication status!"
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
            name_array = @collection.items.properties.map{|h| h.name.to_s.include?("field") ?  Yogo::Collection::Property.get(h.name.to_s.gsub("field_",'').gsub('_','-')).name : nil}
            name_array.delete(nil)
            field_array = @collection.items.properties.map{|h| h.name.to_s.include?("field") ?  h.name : nil}
            name_array.delete(nil)
            field_array.delete(nil)
            csv_string = CSV.generate do |csv|
              csv << name_array
              @collection.items.all(:fields=>field_array).each do |item|
                  csv << name_array.map{|n| item[n].to_s}
              end
            end
            send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)
    end
     
    def upload
      render 'projects/upload'
    end
    
    private
    def get_project
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
      unless current_user.memberships(:project_id => params[:project_id]).empty?
        return @project = Yogo::Project.get(params[:project_id])
      else
        flash[:error] = "You don't have access to that project!"
        redirect_to projects_path()
        return
      end
      #you are member proceed
    end
    
end
