require 'json'

class CardsFromMunFetcher
  def self.fetch(client, mun_id)
  	puts "entramos"
    options = {filter: :open, lists: :open, cards: :open, fields: :name}
    puts "sbhdssdsnsd nasfdn sdn kospd nsk"
    cards=Array.new
    Municipio.find_by(id: mun_id).boards.where(:current_state.nin => ["Descartado"]).each do |board|
    	board_id=board.board_id
    	a=JSON.parse(client.get("/boards/#{board_id}", options))
    	a["cards"].each do |card|
    		cards<<card
    	end
    end
    return cards
  end
end