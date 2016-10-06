require 'trello'

class BoardFetcher
  def self.fetch(client, member_id)
    raise Trello::Error if client.nil? || member_id.nil? || member_id.empty?
    JSON.parse(client.get("/members/#{member_id}/boards", {fields: :name, organization: true}))
  end

  def self.fetch2(client, member_id)
    raise Trello::Error if client.nil? || member_id.nil? || member_id.empty?
    JSON.parse(client.get("/members/#{member_id}/boards", {filter: :closed, fields: :name, organization: true}))
  end
end