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

  get '/boards', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role=="admin")
      respond_to do |format|
        format.html do
          redirect '/admin'
        end
        format.json { status 400 }
      end
    end
    begin
      @boards = BoardAnalyzer.analyze2(BoardFetcher.fetch(client, @user.trello_name),@user)
      @states=@user.municipio.states.pluck(:name)
      @prioridades=["Urgentes","Priorizados","No Priorizados"]
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

    begin
      Trello.configure do |config|
        config.developer_public_key = ENV['PUBLIC_KEY']
        config.member_token = @user.member_token
      end
      JSON.parse(client.put("/boards/#{board_id}/closed", {value: "true"}))
      boards=Board.where({board_id: board_id})
      boards.each do |board|
        board.users.each do |user|
          user.boards.delete(board)
        end
        board.zones.each do |zone|
          zone.boards.delete(board)
        end
        board.destroy
      end

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
          JSON.parse(client.post("/boards/#{@board.id}/powerUps?value=calendar"))
          #Creo el tablero a nivel de BD:
          board_settings = Board.find_or_create_by(board_id: @board.id)
          board_settings.monto=params[:monto]
          board_settings.tipo=params[:tipo]
          board_settings.fondo=params[:fondo]
          board_settings.coords=params[:zona]
          board_settings.users<<@user
          board_settings.municipio=@user.municipio
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
            list1=Trello::List.create({:name=>"Terminadas",:board_id=>@board.id,:pos=>"1"})
            list2=Trello::List.create({:name=>"Haciendo",:board_id=>@board.id,:pos=>"2"})
            list3=Trello::List.create({:name=>"Pendientes",:board_id=>@board.id,:pos=>"3"})
            list4=Trello::List.create({:name=>"Repositorio",:board_id=>@board.id,:pos=>"4"})

            #Crear las tareas por defecto
            @user.municipio.states.each do |state|
              if(state.order=="1")
                state.tasks.each do |taskk|
                  @card1=Trello::Card.create({:name=>"#{taskk.name}",:list_id=>list4.id, :desc=>"#{taskk.desc}"})
                  @card1.save
                end
                
              end
            end
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
            Board.find_by(board_id: @board.id).municipio.users.each do |user|
              if(user.role=="admin" || user.role=="secpla")
                JSON.parse(client.put("/boards/#{@board.id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
              else
                JSON.parse(client.put("/boards/#{@board.id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
              end
            end

            org_name=Trello::Organization.find(org_id).name
            if(org_name="Urgentes")
              JSON.parse(client.put("/boards/#{@board.id}/prefs/background?value=red"))
            end
          end
        else

          #El tablero existe y va a ser editado
          @board=Trello::Board.find(params[:last_board_id])
          JSON.parse(client.post("/boards/#{@board.id}/powerUps?value=calendar"))
          admins=JSON.parse(client.get("/boards/#{@board.id}/members/admins"))

          soyadmin=false
          admins.each do |admin|
            if(admin["id"]==@user.trello_id)
              soyadmin=true
            end
          end
          if(soyadmin)
            #Busco el tablero a nivel de BD:
            board_settings = Board.find_or_create_by(board_id: @board.id)
            board_settings.monto=params[:monto]
            board_settings.tipo=params[:tipo]
            board_settings.fondo=params[:fondo]
            board_settings.coords=params[:zona]
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
            
            if(params[:name]!=@board.name)
              @board.name=params[:name]
              @board.update!
            end
          else
            respond_to do |format|
              format.html do
                flash[:error] = "No tienes permisos de administrador sobre este tablero."
                redirect '/boards'
          end

          format.json { status 400 }
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
      if(params[:edit]=="false")
        flash[:success] = "Proyecto creado exitosamente."
      else
        flash[:success] = "Proyecto editado exitosamente."
      end
      redirect '/boards/'+@board.id
      
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
        if params[:org_id]=='nil'
          @org_id=Trello::Board.find(params[:last_board_id]).organization_id
          if @org_id == nil
            @org_id=""
          end
        else
          @org_id=params[:org_id]
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
