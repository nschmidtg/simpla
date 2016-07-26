require 'mongoid'

class State
  include Mongoid::Document


  has_many :tasks

  field :id, type: String
  field :name, type: String
  field :order, type: String
  
  validates_uniqueness_of :id
  belongs_to :municipio
end