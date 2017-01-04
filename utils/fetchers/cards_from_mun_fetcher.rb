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
      cards<<card
    	end
      if(board.end_date!=nil && board.end_date!="")
        card=Hash.new
        card["boardName"]=a["name"]
        card["due"]=DateTime.parse(board.end_date).to_s.split('T')[0]+"T15:00:00.000Z"
        card["closed"]=false
        card["name"]="Fecha estimada de fin del proyecto"
        cards<<card
      end
    end
    return cards
  end
end