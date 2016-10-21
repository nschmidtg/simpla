require 'trello'

require_relative '../utils/fetchers/board_fetcher'
require_relative '../utils/analyzers/board_analyzer'
require_relative '../utils/fetchers/member_fetcher'
require_relative '../utils/analyzers/member_analyzer'
require_relative '../utils/analyzers/board_details_analyzer'
require_relative '../utils/fetchers/board_details_fetcher'
require_relative '../utils/analyzers/cards_from_mun_analyzer'
require_relative '../utils/fetchers/cards_from_mun_fetcher'

class Ollert

  get '/archivar', :auth => :connected do
    if(@user.role=="secpla" || @user.role=="admin")
      if(@user.municipio.id.to_s==params[:mun_id])
        board=Board.find_by(board_id: params[:board_id])
        board.archivado="true"
        board.save
        respond_to do |format|
          format.html do
            flash[:success] = "Proyecto archivado exitosamente"
            redirect '/boards'
          end

          format.json { status 400 }
        end
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Usted no pertenece a este municipio"
            redirect '/boards'
          end

          format.json { status 400 }
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = "Usted no tiene los permisos de administrador para archivar el proyecto"
          redirect '/boards'
        end

        format.json { status 400 }
      end
    end
  end

  get '/dashboard', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
  

      @mun=Municipio.find_by(id: params[:mun_id])
      @mun_id=@mun.id
      @boards=@mun.boards.where(closed:"false")
    

    respond_to do |format|
      format.html { haml :dashboard }
    end
  end
 
  get '/calendar', :auth => :connected do 
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
  

      @mun=Municipio.find_by(id: params[:mun_id])
      @mun_id=@mun.id
      @token=@user.member_token
    

    respond_to do |format|
      format.html { haml :calendar }
    end
  end

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
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      format.json { {'data' => @organizations }.to_json }
    end
  end

  get '/closed', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  @user.member_token
    end
    if(@user.role=="admin")
      respond_to do |format|
        format.html do
          redirect '/admin'
        end
      end
    end
    begin
      @boards = BoardAnalyzer.analyze2(BoardFetcher.fetch2(client, @user.trello_name),@user)
      @statesd=@user.municipio.states.order(:order => 'asc')
      @states=@statesd.pluck(:name)
      @prioridades=["1. Urgentes","2. Priorizados","3. No Priorizados"]
      @token=@user.member_token
      @closed="true"
    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save

      end

      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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

  get '/boards', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  @user.member_token
    end
    if(@user.role=="admin")
      respond_to do |format|
        format.html do
          redirect '/admin'
        end
      end
    end
    begin
      @boards = BoardAnalyzer.analyze2(BoardFetcher.fetch(client, @user.trello_name),@user)
      @statesd=@user.municipio.states.order(:order => 'asc')
      @states=@statesd.pluck(:name)
      @prioridades=["1. Urgentes","2. Priorizados","3. No Priorizados"]
      @token=@user.member_token

    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save

      end

      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
    if(@user.role=="secpla" || @user.role=="admin")
      begin
        Trello.configure do |config|
          config.developer_public_key = ENV['PUBLIC_KEY']
          config.member_token = @user.member_token
        end
        
        board=Board.find_by(board_id: board_id)
        board.closed="true"
        board.current_state="Descartado"
        board.state_change_dates[9]=Time.now.strftime("%d/%m/%Y %H:%M")
        board.name=board.name.split(' |')[0]+" |Descartado|"
        board.save
        JSON.parse(client.put("/boards/#{board_id}/name", {value: "#{board.name}"}))
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
    else
      respond_to do |format|
        format.html do
          flash[:error] = "Usted no tiene los permisos de administrador para borrar el tablero"
          redirect '/boards'
        end

        format.json { status 400 }
      end
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
    if(@user.role=="secpla" || @user.role=="admin")
      org_id=params[:org_id]
      memb="false"
      if org_id!=""
        data={:name=> params[:name],:organization_id=> org_id}
        memb="true"
      else
        data={:name=> params[:name]}
      end

      zonas=params[:zonas]
        
      if(params[:edit]=="false")
        #El tablero no existe, lo creo
        @board=Trello::Board.create(data)
        
        #Creo el tablero a nivel de BD:
        board_settings = Board.find_or_create_by(board_id: @board.id)
        board_settings.monto=params[:monto]
        board_settings.closed="false"
        board_settings.state_change_dates=Array.new(10)
        board_settings.tipo=Tipo.find_by(id: params[:tipo])
        board_settings.fondo=Fondo.find_by(id: params[:fondo])
        if(params[:coords]=="on")
          board_settings.coords=params[:zona]
        else
          board_settings.coords=""
        end
        board_settings.start_date=params[:start_date]
        board_settings.end_date=params[:end_date]
        board_settings.desc=params[:desc]
        board_settings.name=params[:name]
        #Asigno al admin o secpla como miembro del tablero
        board_settings.users<<@user
        board_settings.municipio=Organization.find_by(org_id: org_id).municipio
        board_settings.save
        if(zonas!=nil)
          zonas.each do |zona_id|
            zona=Zone.find_or_initialize_by( id: zona_id)
            board_settings.zones<<Zone.find_or_initialize_by( id: zona)
            zona.boards<<board_settings
            zona.save
            board_settings.save
          end
        end
        @user.boards<<board_settings
        @user.save
        


        #Cerrar las listas en inglés
        @board.lists.each do |l|
          l.close!
        end
        
        Thread.new do
          #Crear las listas en español
          list1=Trello::List.create({:name=>"Revisadas",:board_id=>@board.id,:pos=>"1"})
          list2=Trello::List.create({:name=>"Terminadas",:board_id=>@board.id,:pos=>"2"})
          list3=Trello::List.create({:name=>"Haciendo",:board_id=>@board.id,:pos=>"3"})
          list4=Trello::List.create({:name=>"Pendientes",:board_id=>@board.id,:pos=>"4"})
        
          #Crear las tareas por defecto
          
  
        end
        Thread.new do
          #Encontrar al usuario como miembro
          board=Board.find_by(board_id: @board.id)
          if(board.municipio.launched=="true")
            board.add_members(client,request.host)
          end
        end
      else

        #El tablero existe y va a ser editado
        @board=Trello::Board.find(params[:last_board_id])
        Thread.new do
          #Encontrar al usuario como miembro
          board=Board.find_by(board_id: @board.id)
          if(board.municipio.launched=="true")
            board.add_members(client,request.host)
          end
        end
      
      
        #Busco el tablero a nivel de BD:
        board_settings = Board.find_or_create_by(board_id: @board.id)
        board_settings.monto=params[:monto]
        board_settings.tipo=Tipo.find_by(id: params[:tipo])
        board_settings.fondo=params[:fondo]
        puts params[:coords]
        if(params[:coords]=="on")
          board_settings.coords=params[:zona]
        else
          board_settings.coords=""
        end
        board_settings.start_date=params[:start_date]
        board_settings.end_date=params[:end_date]
        board_settings.desc=params[:desc]
        board_settings.save
        if(zonas!=nil)
          board_settings.zones.each do |zone|
            board_settings.zones.delete(zone)
          end
          zonas.each do |zona_id|
            zona=Zone.find_or_initialize_by( id: zona_id)
            board_settings.zones<<Zone.find_or_initialize_by( id: zona)
            zona.boards<<board_settings
            zona.save
            board_settings.save
          end
        else
          board_settings.zones.each do |zone|
            board_settings.zones.delete(zone)
          end
        end
        @user.boards<<board_settings
        @user.save
        state=@board.name.split('|')[1]
        if(state!=nil)
          new_name=params[:name]+' |'+state+'|'
        else
          new_name=params[:name]
        end
        if(new_name!=@board.name)
          @board.name=new_name
          board_settings.name=new_name
          board_settings.save
          begin
            @board.update!
          rescue
            respond_to do |format|
              format.html do
                flash[:error] = "No tienes permisos de administrador sobre este tablero, por lo que no puedes editarlo. Pídele a la persona que creó este tablero desde Trello que te nombre Administrador."
                redirect '/admin'
              end
              format.json { status 400 }
            end
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = "No tienes permisos de administrador, por lo que no puedes crear nuevos proyectos."
          redirect '/boards'
        end

        format.json { status 400 }
      end
    end
      


    respond_to do |format|
      if(params[:edit]=="false")
        flash[:success] = "Proyecto creado exitosamente."
      else
        flash[:success] = "Proyecto editado exitosamente."
      end
      redirect "/boards"
      
    end
  end



  get '/new_board', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    begin
      if(@user.role=="secpla" || @user.role=="admin")
        @orgName=params[:orgName]
        Trello.configure do |config|
          config.developer_public_key = ENV['PUBLIC_KEY']
          config.member_token = @user.member_token
        end
        if params[:org_id]==nil
          @org_id=Trello::Board.find(params[:last_board_id]).organization_id
          @municipio=Organization.find_by(org_id: @org_id).municipio
          if @org_id == nil
            @org_id=""
          end
        else
          @org_id=params[:org_id]
          @municipio=Organization.find_by(org_id: @org_id).municipio
          puts @municipio.id
          
        end
        @orgName=Organization.find_by(org_id: @org_id).name
        if(params[:edit]=="true")
          @board=Board.find_by board_id: params[:last_board_id]
          @municipio=@board.municipio
        end
        
      else
        respond_to do |format|
          format.html do
            flash[:error] = "No tienes permisos de administrador, por lo que no puedes crear o modificar proyectos."
            redirect '/boards'
          end

          format.json { status 400 }
        end
      end
      
    rescue Trello::Error => e
      unless @user.nil?
        @user.member_token = nil
        @user.trello_name = nil
        @user.save
      end

      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
