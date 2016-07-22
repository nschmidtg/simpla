require 'mongoid'

class Task
  include Mongoid::Document

  field :id, type: String
  field :name, type: String
  field :desc, type: String
  
  validates_uniqueness_of :id
  embedded_in :state
end