class UserBadge < ActiveRecord::Base
  belongs_to :user
  after_create :notify

  def notify()
  	event = Event.find(self.event_id)
  	#user_badges = UserBadge.where(event_id:self.event_id,user_id: self.user_id,award_status: 1)
  	          
  	 if self.award_status == 1    #Awarded       
        #if Rails.env.production?
          Notification.create(user_id: self.user_id,
  											act_user_id: event.user_id,
  											event_id: event.id,
  											n_type: :new_badge,
  											read: false)
        #end
    end
  end

  def get_badge_filename()
  	b = Badge.find(self.badge_id)
  	b.get_badge_filename()
  end

  def json_format
    event = Event.find(self.event_id)
    {
      user_id: self.user_id,
      user_name: User.find(self.user_id).name,
      event_owner: User.find(event.user_id).name,
      event_owner_id: event.user_id,
      event_name: event.title,
      badge_url: Badge.find(self.badge_id).get_file_Name(),
      school_name: event.loc_name,
      badge_id: self.badge_id,
      user_badge_id: self.id
    }
  end

  def json_list_format
    {"event_title" => Event.find(self.event_id).title,
     "badge_id" => self.badge_id,
     "badge_url" => Badge.find(self.badge_id).get_file_Name(),
     "user_badge_id" => self.id,
    }
  end

end
