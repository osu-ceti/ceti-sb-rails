class Event < ActiveRecord::Base
  belongs_to :user
  has_many :claims, dependent: :destroy
  acts_as_taggable

  searchable do
    text :title, :boost => 5
    text :content, :event_month
    time :start
    string :event_month
  end

  def tag_list_commas
    self.tags.map(&:name).join(', ')
  end

  def event_month
    self.start.strftime('%B %Y')
  end
end