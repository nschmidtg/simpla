require 'mongoid'

class Task
  include Mongoid::Document

  field :id, type: String
  field :name, type: String
  field :desc, type: String
  field :checked, type: String
  
  validates_uniqueness_of :id
  belongs_to :state
  belongs_to :fondo
end