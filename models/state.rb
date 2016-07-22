require 'mongoid'

class State
  include Mongoid::Document


  embeds_many :tasks

  field :id, type: String
  field :name, type: String
  field :order, type: String
  
  validates_uniqueness_of :id
  embedded_in :municipio
end