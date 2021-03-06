class UsersController < ApplicationController

  #before_filter :authenticate_user!
#  before_action :correct_user,   only: [:update, :destroy]
  before_action :admin_user,     only: :destroy

  def index
    params[:per_page] = 15
    @users = SearchService.new.search(User, params)
    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: {users: @users.map{|u| u.json_list_format}}.as_json }
    end
  end

  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html do
        @events = @user.events.order(event_end: :desc).paginate(page: params[:page])
      end
      #format.json { render json: @user }
    end
  end

#  def edit
#    @user = current_user
#  end

  def update
    @user = User.find(current_user.id)
    #@user = User.find(params[:id])
    if @user.update_attributes(secure_params)
      flash[:success] = 'Profile updated'
      redirect_to @user
    else
      @user.errors.full_messages.each do |m|
        flash[:danger] = m
      end
      redirect_to :profile
    end
  end

  def destroy
#    User.find(params[:id]).destroy
    respond_to do |format|
      format.html do
        flash[:success] = 'User deleted'
        redirect_to users_path
      end
      #format.json {render :json => {:state => {:code => 0, status: :ok} }}
    end
  end

  def read_notification
    notification = Notification.find(params[:id])
    notification.update_attribute(:read, true)
    redirect_to notification.link
  end

  def award_badge
    current_user.award_badge(params[:event_id], params[:award])
    redirect_to root_url 
  end

  def show_badges
    @user = User.find(params[:user_id])
    @user_badges = UserBadge.where(user_id: params[:user_id])
  end

  def get_badge
    @user = User.find(params[:user_id])
    @user_badge = UserBadge.find(params[:user_badge_id])
    @event = Event.find(@user_badge.event_id)
  end

  def write_message
    @recipient = User.find(params[:id])
  end

  def send_message
    current_user.send_message(params[:id], params[:user_message])
    #UserMailer.send_message(current_user.id, params[:id], params[:user_message]).deliver_now
    redirect_to(root_url)
  end
  
  private

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless @user.role == 'Admin'
  end

  def secure_params
    p = params.require(:user).permit(:id, :role, :name, :email, :school_id, :biography, :grades, :job_title, :business, :current_password, :tag_list, location_attributes: [:user_id, :address])
    p.each{|k,v| p[k] = v.strip}
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user == @user
  end
end
