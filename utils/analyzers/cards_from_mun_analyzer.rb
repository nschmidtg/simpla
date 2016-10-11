class CardsFromMunAnalyzer
  def self.analyze(data)
    return {} if data.nil? || data.empty?

    {
      name: data["name"],
      lists: data["lists"].map { |list| {name: list["name"], id: list["id"]} },
      cards: data["cards"].map { |card| {name: card["name"], id: card["id"], due: card["due"]} }
    }
  end
end