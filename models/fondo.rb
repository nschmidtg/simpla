require 'mongoid'

class Fondo
  include Mongoid::Document


  has_many :tasks, :dependent => :destroy
  has_many :boards

  field :id, type: String
  field :name, type: String
  field :etapa, type: String
  field :custom, type: String
  
  validates_uniqueness_of :id
  belongs_to :municipio
end