require 'mongoid'

class User
  include Mongoid::Document

  embeds_many :boards

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

  validates_uniqueness_of :trello_id
  validates_uniqueness_of :login_mail
end