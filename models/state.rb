require 'mongoid'

class State
  include Mongoid::Document


  has_many :tasks

  field :name, type: String
  field :order, type: Integer
  
  belongs_to :municipio
end