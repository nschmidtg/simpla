require 'mongoid'

class User
  include Mongoid::Document

  has_many :boards

  field :email, type: String
  field :trello_id, type: String
  field :trello_name, type: String
  field :member_token, type: String
  field :gravatar_hash, type: String
  field :login_mail, type: String
  field :login_pass, type: String
  field :login_name, type: String
  field :login_last_name, type: String
  field :role, type: String

  belongs_to :municipio

end