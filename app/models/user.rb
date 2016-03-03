class User < ActiveRecord::Base
  include PgSearch
  enum role: [:Admin, :Teacher, :Speaker, :Both]
  after_initialize :set_default_role, :if => :new_record?
  after_update :send_password_change_email, if: :needs_password_change_email?
  has_many :events, dependent: :destroy
  has_many :claims, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :devices
  belongs_to :school
  has_one :location, :through => :school
  has_one :location
  accepts_nested_attributes_for :location
  acts_as_taggable
  acts_as_token_authenticatable
  validates_presence_of :name
  validates_length_of :name, :job_title, :business, :grades,  maximum: 70
  validates_length_of :biography, maximum: 2048
  validates :name,
             format: {with: /\A(\S+ )*\S+\z/i, 
                      message: "must be a valid alphanumeric string"}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, format: {with: VALID_EMAIL_REGEX,
                             message: "must be a valid email address"}
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         :lockable
  multisearchable against: [:name, :job_title, :business, :school, :biography]
  pg_search_scope :search_full_text, against: {
    name: 'A',
    job_title: 'B',
    business: 'C',
    biography: 'D'
  }

  def set_default_role
    self.role ||= :Both
    self.set_updates ||= true
    self.set_confirm ||= true
    self.set_claims  ||= true
  end

  def feed
    Event.where('user_id = ?', id).where(active: true)
  end

  def devices
    Device.where('user_id = ?', id)
  end

  def tag_list_commas
    self.tags.map(&:name).join(', ')
  end

  def get_badges

  end

  def get_pending_claims(params)
    Event.joins(:claims).where('claims.user_id' => self.id)
          .where.not(speaker_id: self.id)
          .where(active: true, complete: false)
          .where('claims.cancelled' => false)
          .where('claims.rejected' => false)
          .where('event_start > ?', Time.now) 
          .paginate(page: params[:page], per_page: params[:per_page])
  end
      #.where('claims.active' => true))

  def get_event_approvals(params)
    Event.joins(:claims).where('events.user_id' => self.id)
          .where('events.speaker_id'=> 0)
          .where(active: true)
          .where('claims.active' => true)
          .where('claims.rejected' => false)
          .where('event_start > ?', Time.now)
          .paginate(page: params[:page], per_page: params[:per_page])
  end

  def get_all_events(params)
    Event.where("user_id = ? OR speaker_id = ?",  self.id, self.id)
          .where(active: true) #speaker_id: current_user.id)
          .where('event_start > ?', Time.now)
          .paginate(page: params[:page], per_page: params[:per_page])
  end    
 
  def get_confirmed(params)
    Event.where("user_id = ? OR speaker_id = ?", self.id, self.id)
          .where.not(speaker_id: 0)
          .where(active: true)
          .where('event_start > ?', Time.now)
          .paginate(page: params[:page], per_page: params[:per_page])
  end

  def send_message(to_id, message)
    begin
      UserMailer.send_message(self.id, to_id, message).deliver_now
      Notification.create(user_id: to_id,
                            act_user_id: self.id,
                            event_id: 0,
                            n_type: :message,
                            read: false)
      return true
    rescue
      return false
    end
  end

  def notifications()
    Notification.where(user_id: self.id).order(id: :desc)
  end

  def unread_notifications()
    return Notification.where(user_id: self.id, read: false).count
  end

  def award_badge(event_id, award)
    event = Event.find(event_id)
    if self.id == event.user_id
      if award
        badge_id = School.find(event.loc_id).badge_id
        UserBadge.create(user_id: event.speaker_id, 
                         badge_id: badge_id, 
                         event_id: event.id)
        Notification.create(user_id: event.speaker_id,
                            act_user_id: self.id,
                            event_id: event.id,
                            n_type: :new_badge,
                            read: false)
        event.update(complete: true)
      else
        event.update(complete: true)
      end
    end
  end

  def get_events()
    return Event.where("user_id = ? OR speaker_id = ?",  self.id, self.id)
                .where("event_start > ?", Time.now)
                .where(active: true)
  end

  def clean_user
    claims = self.claims
    claims.each do |claim|
      claim.cancel
    end
    notifications = Notification.where(act_user_id: self.id)
    notifications.each do |n|
      n.update(act_user_id: 0)
    end
  end

  def json_format
    if self.school_id && self.school_id != ""
      school_name =School.find(self.school_id).school_name
    else
      school_name = nil
    end
    user_message = {id: self.id, name:self.name, role:self.role, 
                    grades:self.grades, job_title:self.job_title,
                    business:self.business, biography:self.biography,
                    category:self.speaking_category, school_id:self.school_id,
                    school_name:school_name}
    return user_message
  end

  def json_list_format
    if self.role == "Teacher" || self.role == "Both"
      association = School.find(self.school_id).handle_abbr
    elsif self.role == "Speaker"
      association == self.business
    end
    {"id" => self.id, "name" => self.name, "association" => association}
  end
 
  private
  
    def needs_password_change_email?
      encrypted_password_changed? && persisted?
    end

    def send_password_change_email
      UserMailer.password_changed(id).deliver
    end

end
