require 'mongoid'

class Fondo
  include Mongoid::Document


  has_many :tasks, :dependent => :destroy
  has_many :boards

  field :name, type: String
  field :etapa, type: String
  field :custom, type: String
  
  belongs_to :municipio
end