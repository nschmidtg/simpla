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

  get '/api/v1/load_adj/:board_id' do |board_id|
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token = params["token"]
    end
           
    trello_board=Trello::Board.find(board_id)

    response=""
    trello_board.cards.each do |card|
      att=card.attachments
      if(att.size!=0)
        response=response+"<ul>"
        response=response+"<b>"+card.name+":</b>"
        att.each do |adj|
          response=response+"<li>"
          response=response+"<a href='"+adj.url+"' target='_blank'>"+adj.name+"</a>"
          response=response+"</li>"
        end
        response=response+"</ul>"
      end
    end
    body (response)
    status 200
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

  get '/api/v1/change_predet_task/:id' do |id|
    
    task=Task.find_by(id: id)
    if(task.checked=="true")
      task.checked="false"
    else
      task.checked="true"
    end
    task.save
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

  get '/api/v1/calendarFull/:mun_id' do |mun_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params['token']
    )
    body CardsFromMunFetcher.fetch(client, mun_id).to_json
    #body CardsFromMunAnalyzer.analyze(CardsFromMunFetcher.fetch(client, mun_id)).to_json
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
    if(state!="")
      if board.name.include? "|"
        board.name=board.name.split('|')[0]+" |"+state+"|"
      else
        board.name=board.name+" |"+state+"|"
      end
    else
      if board.name.include? "|"
        board.name=board.name.split('|')[0]
      end
    end
    brd=Board.find_by(board_id: board_id)
    brd.name=board.name
    brd.current_state=state
    muni_state=brd.municipio.states.find_by(name: state)
    if(muni_state!=nil)
      order=muni_state.order
      if(brd.state_change_dates==nil)
        brd.state_change_dates=Array.new(10)
        brd.save
      end
      #if((order.to_i-1)==8 && brd.state_change_dates[order.to_i-1]!=nil)
      #else
        brd.state_change_dates[order.to_i-1]=Time.now.strftime("%d/%m/%Y %H:%M")
      #end
      for i in order.to_i..9
        brd.state_change_dates[i]=nil
      end

    end
    brd.save
    board.save
    if(state=="Finalizado" && brd.closed.to_s=="false")
      JSON.parse(client.put("/boards/#{board_id}/closed?value=true"))
      puts "se cierra"
      brd.closed="true"
      brd.save
    elsif(brd.closed.to_s=="true")
      puts "se abre"
      JSON.parse(client.put("/boards/#{board_id}/closed?value=false"))
      brd.closed="false"
      brd.archivado="false"
      brd.save
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
                if(t.checklist!=nil && t.checklist!="")
                  checklist=JSON.parse(client.post("/checklist?idCard=#{@card1.id}"))["id"]
                  t.checklist.split("|").each do |st|
                    JSON.parse(client.post("/cards/#{@card1.id}/checklist/#{checklist}/checkItem?name=#{st}&idChecklist=#{checklist}"))
                  end
                end
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
                if(t.checklist!=nil && t.checklist!="")
                  checklist=JSON.parse(client.post("/checklist?idCard=#{@card1.id}"))["id"]
                  t.checklist.split("|").each do |st|
                    JSON.parse(client.post("/cards/#{@card1.id}/checklist/#{checklist}/checkItem?name=#{st}&idChecklist=#{checklist}"))
                  end
                end
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
        brd.organization=organization
        brd.save
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
