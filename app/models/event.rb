class Event < ActiveRecord::Base
  extend SimpleCalendar
  belongs_to :user
  belongs_to :school
  has_calendar({:attribute => :event_start})
  has_many :claims, dependent: :destroy
  acts_as_taggable

 searchable do
   text :title, :boost => 5
   text :content, :event_month
   time :event_start
   string :event_month
   integer :loc_id
   integer :user_id
   text :user_name
   text :loc_name
 end

  def tag_list_commas
    self.tags.map(&:name).join(', ')
  end

  def event_month
    self.event_start.strftime('%B %Y')
  end
end
