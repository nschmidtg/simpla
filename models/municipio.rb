require 'mongoid'

class Municipio
  include Mongoid::Document

  has_many :users
  has_many :states

  field :name, type: String
  field :id, type: String

  validates_uniqueness_of :id
end