require 'mongoid'

class Task
  include Mongoid::Document


  field :name, type: String
  field :desc, type: String
  field :checked, type: String
  field :board_ids, type: String
  
  belongs_to :state
  belongs_to :fondo
end