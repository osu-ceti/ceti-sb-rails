class AddAddressToSchool < ActiveRecord::Migration
  def change
  	add_column :schools, :address, :text
  end
end
