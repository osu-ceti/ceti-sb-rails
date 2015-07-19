class API::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
  #protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  skip_before_filter :authenticate_scope!, :only => [:update]

  acts_as_token_authentication_handler_for User

  respond_to :json

  def create
      #   build_resource(sign_up_params)
      #   resource_saved = resource.save
      #   yield resource if block_given?
      #   if resource_saved
      #     if resource.active_for_authentication?
      #       set_flash_message :notice, :signed_up if is_flashing_format?
      #       sign_up(resource_name, resource)
      #       respond_with resource, location: after_sign_up_path_for(resource)
      #     else
      #       set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
      #       expire_data_after_sign_in!
      #       respond_with resource, location: after_inactive_sign_up_path_for(resource)
      #     end
      #   else
      #     clean_up_passwords resource
      #     @validatable = devise_mapping.validatable?
      #     if @validatable
      #       @minimum_password_length = resource_class.password_length.min
      #     end
      #     respond_with resource
      #   end
      # end
      # format.json do
        @user = User.create(sign_up_params)
        if @user.save
          render :json => {:state => 0, status: :ok, :data => @user.attributes }
        else
          render :json => {:state => 1, status: :error, :messages => @user.errors.full_messages}
        end
    #   end
    # end
  end

  def update
    self.resource = resource_class.to_adapter.get!(send(:current_user).to_key)
    @user = User.find(current_user.id)
    puts resource
    #puts account_update_params
    successfully_updated = update_resource(resource, account_update_params)
    if successfully_updated
      sign_in user, resource, :bypass => true
      render json: {state:0,user:@user}
    else
      render json: {state:1}
    end
  end

  def profile
    if current_user.school_id == 1
      return redirect_to :choose
    end
    #build_resource({})
    render json: current_user.as_json.except("authentication_token","created_at","updated_at")
    #return render "users/#{current_user.id}"
  end

  protected

  def update_resource(resource, params)
    resource.update_with_password(params)#params.except(:current_password))
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :role, :email, :school_id, :grades, :biography, :job_title, :business, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:name, :role, :email, :school_id, :grades, :biography, :job_title, :business, :password, :password_confirmation, :current_password)#, location_attributes: [:address])
  end
end