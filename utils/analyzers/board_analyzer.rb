class BoardAnalyzer
  def self.analyze(data)
    return {} if data.nil? || data.empty?

    trello_boards = {}
    data.each do |board|
      organization = board["organization"].nil? ? "My Boards" : board["organization"]["displayName"]
      trello_boards[organization] ||= []
      trello_boards[organization] << board
    end

    trello_boards
  end
  def self.analyze2(data,user)
    return {} if data.nil? || data.empty?

    trello_boards = {}
    esAdmin=false
    if(user.role=="secpla" || user.role=="admin")
      esAdmin=true
      
    end
    data.each do |board|
      
      board["is_admin"]=esAdmin
      organization = board["organization"].nil? ? "My Boards" : board["organization"]["displayName"]
      trello_boards[organization] ||= []
      trello_boards[organization] << board
    end

    trello_boards
  end
  
end