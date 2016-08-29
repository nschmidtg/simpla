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
      board.name=board.name.split('|')[0]+" |"+state+"|"
      brd=Board.find_by(board_id: board_id)
      brd.name=board.name
      brd.save
      board.save
    else
      board.name=board.name+" |"+state+"|"
      brd=Board.find_by(board_id: board_id)
      brd.name=board.name
      brd.save
      board.save
    end
    Thread.new do
      local_board=Board.find_by(board_id: board_id)
      s=local_board.municipio.states.find_by(name: state)
      s.tasks.where(:fondo_id => local_board.fondo.id).each do |t|
        if(t.checked=="true")
          if(t.fondo.id==local_board.fondo.id)

            if(t.board_ids!=nil)
              splitted=t.board_ids.split(',')
              if(!splitted.include?(local_board.id.to_s))
                
                #para verificar que la tarjeta no haya sido creada
                @card1=Trello::Card.create({:name=>"#{t.name}",:list_id=>board.lists.first.id, :desc=>"#{t.desc}"})
                @card1.save
                if(t.board_ids!=nil)
                  t.board_ids=t.board_ids+","+local_board.id.to_s
                else
                  t.board_ids=local_board.id.to_s
                end
                t.save
              
                
              end
            else
  
              #para verificar que la tarjeta no haya sido creada
              @card1=Trello::Card.create({:name=>"#{t.name}",:list_id=>board.lists.first.id, :desc=>"#{t.desc}"})
              @card1.save
              if(t.board_ids!=nil)
                t.board_ids=t.board_ids+","+local_board.id.to_s
              else
                t.board_ids=local_board.id.to_s
              end
              t.save
            end
          end
        end
      end
      if(s.name=="Finalizado" && board.closed=="false")
        JSON.parse(client.put("/boards/#{board_id}/closed?value=true"))
        board.closed="true"
        board.save
      elsif(board.closed=="true")
        JSON.parse(client.put("/boards/#{board_id}/closed?value=false"))
        board.closed="false"
        board.save
      end
                
    end
    
    body board.to_json
    status 200
  end

  get '/api/v1/change_board_priority/:board_id' do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params['token']
    )
     Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  params['token']
    end
    priority=params['priority']
    #puts priority
    board=Trello::Board.find(board_id)
    brd=Board.find_by(board_id: board_id)
    orgs=brd.municipio.organizations
    #data=JSON.parse(client.get("/members/#{params['user_id']}/organizations", {fields: :displayName}))
    #trello_orgs = {}
    orgs.each do |organization|
      if(organization.name.include?(priority))
        board.organization_id=organization.org_id
        board.update!
      end
    end
    
    if(priority=="1. Urgentes")
      JSON.parse(client.put("/boards/#{board_id}/prefs/background?value=red"))
    else
      JSON.parse(client.put("/boards/#{board_id}/prefs/background?value=blue"))
    end
    body Trello::Organization.to_json
    status 200
  end

  
end
