require 'open-uri'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'open_uri_redirections'
class LinksController < ApplicationController

  include LinksHelper
  before_filter :signed_in_user, only: [:create, :destroy, :submit, :unsubmit]
  #in rails4 before_filter will be before_action
  before_filter :check_admin, only: :destroy

  def index

    final_url  =params[:q]
    final_url = final_url.sub(/http:\/\/www.|https:\/\/www.|http:\/\/|https:\/\/|www./, '')
    params[:q] = final_url
    if params[:q]
      @links = Link.search(params)
      respond_to do |format|
        format.js
        format.html
      end
    end

  end
  def show

    @link = Link.find(params[:id])
    @comments = @link.comments.where('score > -10').order('score DESC').paginate(page: params[:page])
    @downvoted_comments = @link.comments.where('score < -10').exists?
    @link_users = @link.link_users.order('score DESC')
    #if @link_users.exists?
      #search = { q: "" }
      #@link_users.each_with_index do |link_user, i|
        #search[:q] = search[:q] + link_user.topic.name + "+"
        #break if i > 2
      #end
      #@related = Link.search(search)
    #end

    respond_to do |format|
      format.html
      format.js
    end
  end
  def downvoted
    link = Link.find(params[:id])
    @comments = link.comments.where("score <= -10")
  end

  def submit
    id = params[:link][:id]
    topic = params[:topic_name]
    @link = Link.find(id)
    if id and topic!= ""
      @link_user = @link.link_with_topic!(topic, current_user, nil)
      publish_to_fb
      respond_to do |format|
        format.js
      end
    end
  end

  def create
    topic = params[:topic_name]
    @topic = Topic.find(params[:topic_val]) if params[:topic_val]!=""

    if topic != "" and data=check_url

      if @link= Link.find_by_url_link(params[:link][:url_link])
        #after upgrading to rails4 use this line instead of previous line:)
        #if @link= Link.find_by url_link: params[:link][:url_link]
        if @link.topics.exists? slug: topic.parameterize
          flash[:notice]="Link already submitted to the topic"
        else 
          @link_user = @link.link_with_topic!(topic, current_user,@topic)

          flash[:success]="Link submitted"
          publish_to_fb
        end
      else
        @link = current_user.links.build(params[:link]) 

        unless /youtube.com|vimeo.com|twitter.com|soundcloud.com/.match(params[:link][:url_link])
          img = link_image(data)
          @link.picture = img if img
        end
        if @link!= nil && @link.save
          @link_user = @link.link_with_topic!(topic, current_user, @topic)
          publish_to_fb
          flash[:success]="Link submitted"
        end
      end
    else 
      flash[:error]= "Enter a proper url"

    end
    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def destroy
    link = Link.find(params[:id])
    @link_id = link.id
    link.destroy
  end
  def unsubmit
    unsubmit = LinkUser.find(params[:unsubmit])
    unsubmit.destroy
    @link_user_id = params[:unsubmit]
    respond_to do |format|
      format.js
    end
  end

  private
  def publish_to_fb
    FacebookLinkNotifyWorker.perform_async(current_user.oauth_token, link_url(@link))
  end
  def check_admin
    redirect_to root_url unless signed_in? and current_user.admin?
  end
end

