require 'json'
require 'require_all'

require_rel '../utils'

class Ollert
  ["/api/v1/*"].each do |path|
    before path do
      if params["token"].nil?
        halt 400, "Missing token."
      end
    end
  end

  get '/api/v1/progress/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params["token"]
    )

    body ProgressChartsAnalyzer.analyze(ProgressChartsFetcher.fetch(client, board_id),
     params["startingList"], params["endingList"]).to_json
    status 200
  end

  get '/api/v1/listchanges/:board_id' do |board_id|
    client = Trello::Client.new developer_public_key: ENV['PUBLIC_KEY'], member_token: params['token']

    lists = client.get("/boards/#{board_id}/lists", filter: 'open').json_into(Trello::List)
    all = Utils::Fetchers::ListActionFetcher.fetch(client, board_id)

    {
      lists: lists.map {|l| {id: l.id, name: l.name}},
      times: Utils::Analyzers::TimeTracker.by_card(all)
    }.to_json
  end

  get '/api/v1/wip/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params["token"]
    )

    body WipAnalyzer.analyze(WipFetcher.fetch(client, board_id)).to_json
    status 200
  end

  get '/api/v1/stats/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params['token']
    )

    body StatsAnalyzer.analyze(StatsFetcher.fetch(client, board_id)).to_json
    status 200
  end

  get '/api/v1/labels/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params['token']
    )

    body LabelCountAnalyzer.analyze(LabelCountFetcher.fetch(client, board_id)).to_json
    status 200
  end

  get '/api/v1/calendar/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params['token']
    )

    body CardsFromBoardAnalyzer.analyze(CardsFromBoardFetcher.fetch(client, board_id)).to_json
    status 200
  end

  get '/api/v1/change_board_state/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params['token']
    )
     Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  params['token']
    end

    state=params['state']

    board=Trello::Board.find(board_id)
    if board.name.include? "|"
      board.name="|"+state+"|"+board.name.split('|')[2]
      board.save
    else
      board.name="|"+state+"| "+board.name
      board.save
    end
    body CardsFromBoardAnalyzer.analyze(CardsFromBoardFetcher.fetch(client, board_id)).to_json
    status 200
  end
end
