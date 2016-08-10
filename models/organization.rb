require 'mongoid'

class Organization
  include Mongoid::Document

  

  field :org_id, type: String
  field :name, type: String

  belongs_to :municipio
end