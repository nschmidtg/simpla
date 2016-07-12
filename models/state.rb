require 'mongoid'

class State
  include Mongoid::Document

  field :state_id, type: String
  field :name, type: String
  field :position, type: String

  embedded_in :user
end