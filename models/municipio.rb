require 'mongoid'

class Municipio
  include Mongoid::Document

  embeds_many :users
  embeds_many :states

  field :name, type: String
  field :id, type: String

  validates_uniqueness_of :id
end