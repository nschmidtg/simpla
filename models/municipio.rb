require 'mongoid'

class Municipio
  include Mongoid::Document

  has_many :users, :dependent => :destroy
  has_many :fondos, :dependent => :destroy
  has_many :states, :dependent => :destroy
  has_many :zones, :dependent => :destroy
  has_many :boards, :dependent => :destroy
  has_many :organizations, :dependent => :destroy
  
  field :name, type: String
  field :launched, type: String

end