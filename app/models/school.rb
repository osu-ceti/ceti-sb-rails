class School < ActiveRecord::Base
  include PgSearch
  has_one :badge
  has_many :users, -> { where('role = ? OR role = ?', 1, 3) }
  has_many :events, dependent: :destroy
  acts_as_taggable

  #reverse_geocoded_by :latitude, :longitude, :address => :address
  #after_validation :reverse_geocode

  pg_search_scope :search_full_text, 
    against: {
      school_name: 'A',
      loc_addr: 'B',
      loc_city: 'C',
      loc_state: 'D',
    },
    using: { 
      tsearch: {
	dictionary: "english",
	tsvector_column: "search_vector",
	prefix: true
      }
    }

  def json_format
    return {
      id: self.id, 
      name: self.school_name,
      address: self.loc_addr, 
      city: self.loc_city,
      state: self.loc_state, 
      zip: self.loc_zip,
      phone: self.phone
    }
  end

  def json_list_format
    city_state = self.loc_city+", "+self.loc_state
    return {"id" => self.id, 
	    "school_name" => self.school_name,
	    "city_state" => city_state,
	    "badge_id" => self.badge_id}
  end

  def handle_abbr
    value = self.school_name
    if value == nil
      return nil
    end
    value = value.titlecase
    abbr = {"Sch" => " School ", "Ln" => "Lane", "Elem" => "Elementary"}
    values = value.split(" ")
    newvalues =[]
    values.each do |v|
      if abbr[v] != nil
	newvalues += [abbr[v]]
      else
	newvalues += [v]
      end
    end
    newvalues.join(" ")
  end
end
