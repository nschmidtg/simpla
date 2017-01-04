require 'json'

class CardsFromMunFetcher
  def self.fetch(client, mun_id)
    options = {filter: :open, lists: :open, cards: :open, fields: "name,"}
    cards=Array.new
    Municipio.find_by(id: mun_id).boards.where(:current_state.nin => ["Descartado"]).each do |board|
    	board_id=board.board_id
        boardName=""
    	a=JSON.parse(client.get("/boards/#{board_id}", options))
    	a["cards"].each do |card|
            boardName=card["boardName"]
            card["boardName"]=a["name"]
            #card["finish"]=board.end_date
    		cards<<card
    	end
    end
    return cards
  end
end