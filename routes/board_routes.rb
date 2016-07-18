require 'trello'

require_relative '../utils/fetchers/board_fetcher'
require_relative '../utils/analyzers/board_analyzer'
require_relative '../utils/fetchers/member_fetcher'
require_relative '../utils/analyzers/member_analyzer'
require_relative '../utils/analyzers/board_details_analyzer'
require_relative '../utils/fetchers/board_details_fetcher'

class Ollert
 

  get '/organizations', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )

    begin
      @organizations = OrganizationFetcher.fetch(client, @user.trello_name)
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
      format.json { {'data' => @organizations }.to_json }
    end
  end

  get '/boards', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )

    begin
      @boards = BoardAnalyzer.analyze(BoardFetcher.fetch(client, @user.trello_name))
      @states=["No iniciado","Formulación","Observado","Licitación","Ejecución"]
      @prioridades=["Alta Prioridad","Baja Prioridad","No Priorizados"]
      @token=@user.member_token
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

   get '/boards/delete/:board_id', :auth => :connected do |board_id|
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )

    begin
      Trello.configure do |config|
        config.developer_public_key = ENV['PUBLIC_KEY']
        config.member_token = @user.member_token
      end
      JSON.parse(client.put("/boards/#{board_id}/closed", {value: "true"}))


    rescue Trello::Error => e
      

      respond_to do |format|
        format.html do
          flash[:error] = "Usted no tiene los permisos de administrador para borrar el tablero"
          redirect '/boards'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      flash[:success] = "Proyecto eliminado."
      redirect '/boards'
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
      org_id=params[:org_id]
      memb="false"
      if org_id!=""
        desc="|#{params[:monto]}|#{params[:tipo]}|#{params[:fondo]}|#{params[:zona]}|"
        data={:name=> params[:name],:description=> desc,:organization_id=> org_id}
        memb="true"
      else
        desc="|#{params[:monto]}|#{params[:tipo]}|#{params[:fondo]}|#{params[:zona]}|"
        data={:name=> params[:name],:description=> desc}
      end

      
        
      if(params[:edit]=="false")
        #El tablero no existe
        @board=Trello::Board.create(data)
        #Cerrar las listas en inglés
        @board.lists.each do |l|
          l.close!
        end
        
        Thread.new do
          #Crear las listas en español
          list1=Trello::List.create({:name=>"Terminadas",:board_id=>@board.id,:pos=>"1"})
          list2=Trello::List.create({:name=>"Haciendo",:board_id=>@board.id,:pos=>"2"})
          list3=Trello::List.create({:name=>"Pendientes",:board_id=>@board.id,:pos=>"3"})

          #Crear las tareas por defecto
          @card1=Trello::Card.create({:name=>"Tarea defecto 1",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
          @card2=Trello::Card.create({:name=>"Tarea defecto 2",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
          @card3=Trello::Card.create({:name=>"Tarea defecto 3",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
          @card4=Trello::Card.create({:name=>"Tarea defecto 4",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
          @card5=Trello::Card.create({:name=>"Tarea defecto 5",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
          @card6=Trello::Card.create({:name=>"Tarea defecto 6",:list_id=>list3.id, :desc=>"Esta es la descripción de la tarea por defecto"})
        end
        Thread.new do
          #Encontrar al usuario como miembro
          member_current=Trello::Member.find(Trello::Token.find(@user.member_token).member_id)
          @board.add_member(member_current,type=:admin)
          members=Trello::Organization.find(@board.organization_id).members
          members.each do |m|
            @board.add_member(m,type=:admin)
          end
          members.each do |m|
            if m.id!=member_current.id
              @board.add_member(m,type=:normal)
            end
          end
        end
      else
        #El tablero existe y va a ser editado
        @board=Trello::Board.find(params[:last_board_id])
        #@board.description="|#{params[:monto]}|#{params[:tipo]}|#{params[:fondo]}|#{params[:zona]}|"
        
        @board.name=params[:name]
        JSON.parse(client.put("/boards/#{params[:last_board_id]}/desc", {value: desc}))
        @board.update!
        
      end
      
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
      Trello.configure do |config|
        config.developer_public_key = ENV['PUBLIC_KEY']
        config.member_token = @user.member_token
      end
      if params[:org_id]=='nil'
        @org_id=Trello::Board.find(params[:last_board_id]).organization_id
        if @org_id == nil
          @org_id=""
        end
      else
        @org_id=params[:org_id]
      end
      
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
