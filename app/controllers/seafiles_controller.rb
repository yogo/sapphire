class SeafilesController < ApplicationController

  # requires params[:host], params[:password], params[:username]
  def set_token
  	begin
	  	if sea = Seafile.new(params[:host], params[:username],params[:password])
	  		if sea.token.nil?
	  			 flash[:warning] = "Seafile Username and Password combination did not work!"
	  	    else
	    	  current_user.seafile_host= params[:host]
	    	  current_user.seafile_token = sea.token
	    	  current_user.save
	    	end
	    else
	      flash[:warning] = "Seafile Setup failed!"
		end
	rescue => e
		flash[:warning] = e.message
	end
  	redirect_to edit_user_registration_url
    # respond_to do |format|
    #   format.json { render :json => {:token => sea.token} }
    # end
  end

end