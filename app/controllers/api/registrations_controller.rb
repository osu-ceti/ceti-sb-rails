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
        if @user.errors.messages == {}
          UserMailer.welcome(@user.id).deliver_now
          render :json => {:state => 0, status: :ok, :data => @user.attributes }
        else
          render :json => {:state => 1, status: :error, :messages => @user.errors.full_messages}
        end
    #   end
    # end
  end

  def destroy
    resource.soft_delete
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_flashing_format?
    yield resource if block_given?
    render json: {state:0, message: "Your account has been deleted!"}
  end

  def update
    self.resource = resource_class.to_adapter.get!(send(:current_user).to_key)
    @user = User.find(current_user.id)
    puts resource
    successfully_updated = update_resource(resource, account_update_params)
    if successfully_updated
      #sign_in user, resource, :bypass => true
      profile = @user.attributes
      profile[:school_name] = School.find(profile["school_id"]).school_name
      render json: {state:0,user:profile}
    else
      render json: {state:1, message: @user.errors.full_messages.join('\n')}
    end
  end

  def settings
    u = current_user
    render json: {set_updates: u.set_updates, set_confirm: u.set_confirm, set_claims: u.set_claims}
  end

  def update_settings
    user = current_user
    if user.update(settings_params)
      render json: {state: 0}
    else
      render json: {state: 1}
    end
  end

  def profile
    profile = current_user.attributes
    profile[:school_name] = School.find(profile["school_id"]).school_name
    render json: profile.as_json.except("authentication_token","created_at","updated_at","encrypted_password","reset_password_token","reset_password_sent_at", "remember_created_at")
  end

  protected

  def update_resource(resource, params)
    resource.update_with_password(params)#params.except(:current_password))
  end

  private

  def settings_params
    params.require(:user).permit(:set_updates, :set_confirm, :set_claims)
  end

  def sign_up_params
    p = params.require(:user).permit(:name, :role, :email, :school_id, :grades, :biography, :job_title, :business, :password, :password_confirmation)
    p.each{ |k,v| p[k] = v.strip}
  end

  def account_update_params
    p = params.require(:user).permit(:name, :role, :email, :school_id, :grades, :biography, :job_title, :business, :password, :password_confirmation, :current_password)#, location_attributes: [:address])
    p.each{ |k,v| p[k] = v.strip}
  end
end
