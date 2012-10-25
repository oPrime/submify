class LinksController < ApplicationController

  before_filter :signed_in_user, only: [:create, :destroy]
  before_filter :correct_user, only: :destroy

  def create

    @link = current_user.links.build(params[:link])

    if @link.save

    current_user.link_with_user!(@link)
      flash[:success] = "Link submitted"
      redirect_to root_url
    else
      render 'static_pages/home'
    end
  end

  def destroy
    
    current_user.unlink_with_user!(@link)

    redirect_to root_url unless @link.users.exists? current_user
  end

  private
    def correct_user
      @link = current_user.links.find_by_id(params[:id])
      redirect_to root_url if @link.nil?
    end
   
end

