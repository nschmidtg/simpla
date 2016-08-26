require 'mongoid'

class Tipo
  include Mongoid::Document


  has_many :boards

  field :name, type: String

  belongs_to :municipio
end