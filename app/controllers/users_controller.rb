class UsersController < ApplicationController

  #before_filter :authenticate_user!
  #before_action :correct_user,   only: [:update, :destroy]
  #before_action :admin_user,     only: :destroy

  def index
    @search = Sunspot.search(User) do
      fulltext params[:search]
      paginate(page: params[:page])
    end
    if params[:search]
      @users = @search.results
    elsif params[:tag]
      @users = User.tagged_with(params[:tag]).paginate(page: params[:page])
    else
      @users = User.all.paginate(page: params[:page])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users.as_json }
    end
  end

  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html do
        @events = @user.events.paginate(page: params[:page])
      end
      format.json { render json: @user }
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(secure_params)
      flash[:success] = 'Profile updated'
      redirect_to @user
    else
      redirect_to @user, :alert => 'Unable to update user.'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    respond_to do |format|
      format.html do
        flash[:success] = 'User deleted'
        redirect_to users_path
      end
      format.json {render :json => {:state => {:code => 0, status: :ok} }}
    end
  end

  private

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless @user.role == 'Admin'
  end

  def secure_params
    params.require(:user).permit(:id, :role, :name, :email, :school_id, :grades, :job_title, :business, :current_password, :tag_list, location_attributes: [:user_id, :address])
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user == @user
  end
end