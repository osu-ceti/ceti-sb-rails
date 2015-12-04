class API::ClaimsController < API::ApplicationController
  before_action :set_claim, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update]

  respond_to :json

  def index
    respond_to do |format|
      format.html do
        @claims = Claim.all.paginate(page: params[:page])
      end
      format.json do
        @claims = Claim.all
        render json: @claims.as_json
      end
    end
  end

  def pending_claims
    #params = params.require(:event_id)
    if params[:event_id]
      event = Event.find(params[:event_id])
    else
      #render_401 
    end
    claims = event.pending_claims()
    # claims = Claim.where(event_id: event_id)
    # results = Array.new(claims.count){Hash.new}
    # for i in 0..claims.count-1
    #   user = User.find(claims[i].user_id)
    #   results[i] = {"user_id" => user.id, "event_id"=>event_id, "user_name" => user.name, "business" => user.business, "job_title" => user.job_title, "school_id"  =>  user.school_id, "claim_id"=> claims[i].id}
    # end
    render json: {:claims => claims}.as_json
  end


  def show
    @claim = Claim.find(params[:id])
    user = User.find(@claim.user_id)
    result = {"user_id" => user.id, "event_id"=>@claim.event_id, "user_name" => user.name, "business" => user.business, "job_title" => user.job_title, "school_id"  =>  user.school_id, "claim_id"=> @claim.id}
    render json: result.as_json
  end

  def create
    # Note: claim event from the event controller is used instead
    @claim = Claim.new(params[:id])
    respond_to do |format|
      format.html do
        if @claim.save
          render 'static_pages/home'
          flash[:notice] = 'Claim was successfully created.'
        else
          render 'static_pages/home'
        end
      end
      format.json do
        if @claim.save
          render :json => {:state => {:code => 0}, :data => @claim.to_json }
        else
          render :json => {:state => {:code => 1, :messages => @claim.errors.full_messages} }
        end
      end
    end
  end



  def update
    flash[:notice] = 'Claim was successfully updated.'
    if @claim.update(claim_params)
      render @claim
    end
  end


  def reject
    @claim = Claim.find(params[:id])
    @claim.reject()
    render json: {status: 0, user_name: User.find(@claim.user_id).name, event_title: Event.find(@claim.event_id).title}
  end

  def cancel
    @claim = Claim.find(params[:id])
    @claim.cancel()
    render json: {status: 0}
  end

  def destroy
    @claim.destroy
    respond_with(@claim)
  end

  def teacher_confirm
    # Teacher confirms a speaker
    @event = Event.find(params[:event_id])
    @claim = Claim.find(params[:claim_id])
    if current_user.id == @event.user_id and @claim.teacher_confirm(@event)
      # @event.update(speaker_id: @claim.user_id)
      # if User.find(@claim.user_id).set_confirm
      #   UserMailer.confirm_speaker(@event.user_id, @claim.user_id, @event.id).deliver_now
      # end
      # Notification.create(user_id: @claim.user_id,
      #                     act_user_id: @event.user_id,
      #                     event_id: @event.id,
      #                     n_type: :confirm_speaker,
      #                     read: false)
      render json: {status: 0, event: @event.jsonEvent(current_user.id)}
    else
      render json: {status: 1}
    end
  end

  def speaker_confirm
    @event = Event.find(params[:event_id])
    @claim = Claim.find(params[:claim_id])
    if @claim.update_attribute(:confirmed_by_speaker, true)
      redirect_to(root_url)
      flash[:notice] = 'Event was successfully confirmed.'
    end
  end


  private
    def set_claim
      @claim = Claim.find(params[:id])
    end

    def claim_params
      params.require(:claim).permit(:event_id, :user_id)
    end

    # Confirms the correct user.
    def correct_user
      @user = Claim.find(params[:id]).user
      redirect_to(root_url) unless current_user == @user
    end

    # Confirms an admin user.
    def admin_user
      redirect_to(root_url) unless current_user.role == 'Admin'
    end

  # def jsonEvent(event)
  #   school_name = nil
  #   user_name = nil
  #   if event.loc_id
  #     school_name = School.find(event.loc_id).school_name
  #   end
  #   if event.user_id
  #     user_name = User.find(event.user_id).name
  #   end
  #   result = event.attributes
  #   result[:user_name] = user_name
  #   result[:school_name] = school_name
  #   if event.speaker_id
  #     result[:speaker] = User.find(event.speaker_id).name
  #   else
  #     result[:speaker] = "TBA"
  #   end
  #   if Claim.exists?(event_id: event.id, user_id: current_user.id)
  #     result[:claim] = true
  #   else
  #     result[:claim] = false
  #   end
  #   return result
  # end

end
