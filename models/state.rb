require 'mongoid'

class State
  include Mongoid::Document


  has_many :tasks

  field :name, type: String
  field :order, type: String
  
  belongs_to :municipio
end