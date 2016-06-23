require 'json'

class CardsFromBoardFetcher
  def self.fetch(client, board_id)
    raise Trello::Error if client.nil? || board_id.nil? || board_id.empty?

    options = {filter: :open, lists: :open, cards: :open, fields: :name}

    JSON.parse(client.get("/boards/#{board_id}", options))
  end
end