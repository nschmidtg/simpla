require 'trello'

class OrganizationFetcher
  def self.fetch(client, member_id)
    raise Trello::Error if client.nil? || member_id.nil? || member_id.empty?
    JSON.parse(client.get("/members/#{member_id}/organizations", {fields: :displayName}))
  end
end