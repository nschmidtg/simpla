require 'mongoid'

class Municipio
  include Mongoid::Document

  has_many :users, :dependent => :destroy
  has_many :states, :dependent => :destroy
  has_many :boards, :dependent => :destroy
  has_many :zones, :dependent => :destroy

  field :name, type: String
  field :id, type: String

  validates_uniqueness_of :id
end