class EventsController < ApplicationController
  before_action :set_event,           only: [:show]
  #before_action :authenticate_user!
  before_action :teacher_user,        only: [:create]
  before_action :correct_user,        only: [:edit, :update]
  before_action :admin_user,          only: :destroy

  class InvalidTime < StandardError
  end
  class InvalidPreceedingTime < StandardError
  end
  class MissingTime < StandardError
  end
  class MissingTitle < StandardError
  end
  class EventInPast < StandardError
  end

  rescue_from InvalidPreceedingTime, :with => :invalid_preceeding_time

  def index
    if not user_signed_in?
      redirect_to :signin
      return
    end
    if params[:location] and params[:zip] != ""
      zip = Zipcode.where(zip: params[:zip]).first
      if params[:radius] != ""
        radius = eval(params[:radius]) * 1609.34
      else
        radius = 10 * 1609.34
      end
      @events = SearchService.new.events_by_location(zip.lat, zip.long, radius, params)
    else
      @events = SearchService.new.search(Event, params)
    end
    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: list_events(@events).as_json }
    end
  end

  def show
    if user_signed_in?
      respond_to do |format|
        format.html do
          @event = Event.find(params[:id])
        end
        #format.json do
        #  @event = Event.find(params[:id])
        #  render json: @event.json_format.as_json
        #end
      end
    else
      redirect_to :signin
    end
  end

  def create
    begin
      if user_signed_in?
        params = event_params
        @event = current_user.events.build(params)
        adjust_time(@event)
        validate_event(@event)
        respond_to do |format|
          format.html do
            if @event.save
              flash[:success] = 'Event created!'
              redirect_to root_path
            else
              #@event.errors.messages.map{|x,y| flash.now['danger'] = x.id2name }
              @event.errors.full_messages.each do |x|
                flash.now['danger'] = x
              end
              @feed_items = []
              #flash.now['danger'] = "Event creation failed!\nPlease complete required fields."
              render :new  #'static_pages/home'
            end
          end
        end
      else
        redirect_to signin
      end
    rescue InvalidTime
      flash.now['danger'] = "You must enter a valid date."
      render :new
    rescue InvalidPreceedingTime
      flash.now['danger'] = "You must enter a start time that preceeds the end time."
      render :new
    rescue ArgumentError
      flash.now['danger'] = "You must enter a start time that preceeds the end time."
      render :new
    rescue MissingTitle
      flash.now['danger'] = "You are missing a valid title"
      render :new
    rescue MissingTime
      flash.now['danger'] = "You are missing a valid start or end time"
      render :new
    rescue EventInPast
      flash.now['danger'] = "You have entered a start time that has already elapsed."
      render :new
    end
  end

  def new
    if user_signed_in?
      if current_user.school_id > 1
        @event = current_user.events.build
      else
        redirect_to :choose
      end
    else
      redirect_to :signin
    end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    success = false
    updated = false
    @event = Event.find(params[:id])
    params = event_params # Run the parameters through safety
    if params == {}
      raise ActionController::ParameterMissing
    end
    begin
      attrs = @event.attributes
      @event.attributes = params
      adjust_time(@event)
      # Check if the new parameters match the old.  (Is there an update?)
      if not params.map{|x,y| attrs[x] == @event[x]}.all?
        updated = true
        validate_event(@event) # Check for violations of input
        success = @event.save # Save the event
        if success and Rails.env.production?
          @event.handle_update() # Handle notifications
        end
      end
    rescue InvalidTime
      flash.now['danger'] = "You must enter a valid date."
      success = false
    rescue InvalidPreceedingTime
      flash.now['danger'] = "You must enter a start time that preceeds the end time."
      success = false
    rescue ArgumentError
      flash.now['danger'] = "You must enter a start time that preceeds the end time."
      success = false
    rescue MissingTitle
      flash.now['danger'] = "You are missing a valid title"
      success = false
    rescue MissingTime
      flash.now['danger'] = "You are missing a valid start or end time"
      success = false
    rescue EventInPast
      flash.now['danger'] = "You have edited the event to be in the past"
      success = false
    end

    respond_to do |format|
      if @event && success && updated
        format.html do
          flash[:success] = 'Event updated'
          redirect_to @event
        end
        #format.json {render :json => {:state => {:code => 0}, status: :ok, :data => @event.json_format.to_json }}
        format.all { render_404 }
      elsif @event && !success && updated
        @event.errors.full_messages.each do |x|
          flash.now['danger'] = x
        end
        format.html {render :edit }
        #format.json {render :json => {:state => {:code => 1, status: :error, :messages => @user.errors.full_messages} }}
        format.all {render_404}
      elsif @event && !updated
        format.html {redirect_to @event}
      end
    end
  end

  def cancel
    @event = Event.find(params[:id])
    if current_user.id == @event.user_id
      @event.cancel(current_user.id)
      redirect_to root_url
    end
  end

  def destroy
    @event = Event.find params[:id]
    if current_user.id == @event.user_id
      respond_to do |format|
        format.html do
          @event.destroy
        end
        #format.json do
        #  if @event.destroy
        #    render :json => {:state => {:code => 0}}
        #  else
        #    render :json => {:state => {:code => 1, :messages => @user.errors.full_messages} }
        #  end
        #end
      end
    end
  end

  def claim_event
    # TODO Handle a speaker already being selected
    begin
      @event = Event.find(params[:event_id])
      @event.claims.create!(:user_id => params[:user_id])
      flash[:success] = "You have claimed event: #{@event.title}"
      redirect_to(root_url)
    rescue ActiveRecord::RecordNotFound
      flash.now['danger'] = "Event not found"
      redirect_to(root_url)
    end
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end

    def list_events(events)
      return events.map{|e| e.json_list_format}
    end

    def event_params
      params.require(:event).permit(:content, :title, :tag_list, :event_start, :event_end, :loc_id, :time_zone)
    end

    def validate_event(event)
      if not event.event_start? or not event.event_end?
        raise MissingTime
      elsif event.title == ""
        raise MissingTitle
      elsif event.event_start >= event.event_end
        raise InvalidPreceedingTime
      elsif event.event_start <= Time.now
        raise EventInPast
      end
    end

    def adjust_time(event)
      if event.event_start and event.event_end
        time_offset = Time.now.in_time_zone(event.time_zone).utc_offset
        event.event_start -= time_offset
        event.event_start = event.event_start.in_time_zone("UTC")
        event.event_end -= time_offset
        event.event_end = event.event_end.in_time_zone("UTC")
      else
        raise InvalidTime
      end
    end


  # Confirms the correct user.
  def correct_user
    @user = Event.find(params[:id]).user
    redirect_to(root_url) unless current_user == @user
  end

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless current_user && current_user.role == 'Admin'
  end
end
