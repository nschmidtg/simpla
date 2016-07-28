require 'mongoid'

class Zone
  include Mongoid::Document


  has_and_belongs_to_many :boards

  field :id, type: String
  field :name, type: String
  field :coords, type: String
  
  belongs_to :municipio
end