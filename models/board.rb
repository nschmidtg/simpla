require 'mongoid'

class Board
  include Mongoid::Document

  has_and_belongs_to_many :users
  has_and_belongs_to_many :zones

  field :board_id, type: String
  field :starting_list, type: String
  field :ending_list, type: String
  field :monto, type: String
  field :fondo, type: String
  field :coords, type: String
  field :name, type: String
  field :desc, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :closed, type: String


  belongs_to :municipio
  belongs_to :fondo
  belongs_to :tipo
  
end