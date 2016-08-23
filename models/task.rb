require 'mongoid'

class Task
  include Mongoid::Document


  field :name, type: String
  field :desc, type: String
  field :checked, type: String
  field :card_id, type: String
  
  belongs_to :state
  belongs_to :fondo
end