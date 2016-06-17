require 'trello'

require_relative '../utils/fetchers/board_fetcher'
require_relative '../utils/analyzers/board_analyzer'
require_relative '../utils/fetchers/member_fetcher'
require_relative '../utils/analyzers/member_analyzer'
require_relative '../utils/analyzers/board_details_analyzer'
require_relative '../utils/fetchers/board_details_fetcher'

class Ollert
  get '/boards', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )

    begin
      @boards = BoardAnalyzer.analyze(BoardFetcher.fetch(client, @user.trello_name))
    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save
      end

      respond_to do |format|
        format.html do
          flash[:error] = "There's something wrong with the Trello connection. Please re-establish the connection."
          redirect '/'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      format.html { haml :boards }
      format.json { {'data' => @boards }.to_json }
    end
  end

  post '/create_project', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token = @user.member_token
    end


    begin
      last_board_id=params[:last_board_id]
      last_board=Trello::Board.find(last_board_id)
      memb="false"
      if last_board.organization_id!=nil
        data={:name=> params[:name],:description=> "Descripción",:organization_id=> last_board.organization_id}
        memb="true"
      else
        data={:name=> params[:name],:description=> "Descripción"}
      end

      @board=Trello::Board.create(data)
      @board.lists.each do |l|
        l.close!
      end
      list1=Trello::List.create({:name=>"Terminadas",:board_id=>@board.id,:pos=>"1"})
      list2=Trello::List.create({:name=>"Haciendo",:board_id=>@board.id,:pos=>"2"})
      list3=Trello::List.create({:name=>"Pendientes",:board_id=>@board.id,:pos=>"3"})
      @card1=Trello::Card.create({:name=>"Tarea defecto 1",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
      @card2=Trello::Card.create({:name=>"Tarea defecto 2",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
      @card3=Trello::Card.create({:name=>"Tarea defecto 3",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
      @card4=Trello::Card.create({:name=>"Tarea defecto 4",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
      @card5=Trello::Card.create({:name=>"Tarea defecto 5",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
      @card6=Trello::Card.create({:name=>"Tarea defecto 6",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
      member_current=Trello::Member.find(Trello::Token.find(@user.member_token).member_id)
      @board.add_member(member_current,type=:admin)
      members=Trello::Organization.find(@board.organization_id).members
      members.each do |m|
        @board.add_member(m,type=:admin)
      end
      #@board.add_member(@user,type=:admin)
      # members=Trello::Organization.find(@board.organization_id).members
      # @board.add_member(members.first,type=:admin)
      # if memb=="true"
      #   members=Trello::Organization.find(@board.organization_id).members
      #   members.each do |m|
      #     begin
      #       @board.add_member(m,type=:admin)
      #     rescue
      #     end
      #   end
      # end
    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save
      end

      respond_to do |format|
        format.html do
          flash[:error] = "There's something wrong with the Trello connection. Please re-establish the connection."
          redirect '/'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      flash[:success] = "Proyecto creado exitosamente."
      redirect '/boards/'+@board.id
      
    end
  end

  get '/new_board', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )

    begin
      @orgName=params[:orgName]
      @last_board_id=params[:last_board_id]
      puts @orgName
      #@boards = BoardAnalyzer.analyze(BoardFetcher.fetch(client, @user.trello_name))
    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save
      end

      respond_to do |format|
        format.html do
          flash[:error] = "There's something wrong with the Trello connection. Please re-establish the connection."
          redirect '/boards'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      format.html { haml :new_board }
      
    end
  end

  get '/boards/:board_id', :auth => :connected do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )

    begin
      details = BoardDetailsAnalyzer.analyze(BoardDetailsFetcher.fetch(client, board_id))
      @board_name = details[:name]
      @board_lists = details[:lists]

      board_settings = @user.boards.find_or_create_by(board_id: board_id)

      list_ids = @board_lists.map {|bl| bl[:id]}
      board_settings.starting_list = saved_list_or_default(board_settings.starting_list, list_ids, list_ids.first)
      board_settings.ending_list = saved_list_or_default(board_settings.ending_list, list_ids, list_ids.last)

      board_settings.save

      @board_lists = @board_lists.to_json
      @starting_list = board_settings.starting_list
      @ending_list = board_settings.ending_list
      @token = @user.member_token
    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save
      end

      respond_to do |format|
        format.html do
          flash[:error] = "There's something wrong with the Trello connection. Please re-establish the connection."
          redirect '/'
        end

        format.json { status 400 }
      end
    end

    @board_id = board_id

    @title = @board_name
    haml :analysis
  end

  put '/boards/:board_id', :auth => :connected do |board_id|
    board_settings = @user.boards.find_or_create_by(board_id: board_id)
    board_settings.starting_list = params["startingList"] || board_settings.starting_list
    board_settings.ending_list = params["endingList"] || board_settings.ending_list
    board_settings.save
  end

  def saved_list_or_default(saved_list, list_options, default_list)
    saved_list.nil? ? default_list : list_options.find {|lo| lo == saved_list} || default_list
  end
end
