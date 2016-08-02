class Ollert
  get '/', :auth => :none do
    if !@user.nil? && !@user.member_token.nil?
      redirect '/boards'
    end
    
    haml :landing
  end

  not_found do
    flash[:error] = "The page requested could not be found."
    redirect '/'
  end

  post '/authorize', :auth => :none do
    require 'digest'
    mail=params[:mail]
    password=params[:password]
    Municipio.includes(:users).each do |muni|
      muni.users.all.each do |user|
        if(user!=nil)
          if(user.login_mail==mail)
            hash=Digest::SHA256.base64digest password
        
            if(hash==user.login_pass)
             
              respond_to do |format|
                format.html { haml :authorize }
              end
            else
              flash[:error] = "Contraseña no válida"
              redirect '/'
            end
        
          end
        end
      end

    end
    flash[:error] = "Correo no registrado"
    redirect '/'
    
    
    
  end



  get '/seed', :auth => :none do

    states=Array.new()

    mun1=Municipio.find_or_initialize_by id: "1"
    mun1.name="Municipalidad de Til Til"
    estado1=State.find_or_initialize_by id: "1"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun1
    estado1.save
    states<<estado1

    estado2=State.find_or_initialize_by id: "2"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun1
    estado2.save
    states<<estado2

    estado3=State.find_or_initialize_by id: "3"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun1
    estado3.save
    states<<estado3
    
    estado4=State.find_or_initialize_by id: "4"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun1
    estado4.save
    states<<estado4
    
    estado5=State.find_or_initialize_by id: "5"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun1
    estado5.save
    states<<estado5
    
    
        
    mun1.save

    


    mun2=Municipio.find_or_initialize_by id: "2"
    mun2.name="Municipalidad de Llay Llay"
    estado1=State.find_or_initialize_by id: "6"
    estado1.name="No iniciado2"
    estado1.order="1"
    estado1.municipio=mun2
    estado1.save
    states<<estado1

    estado2=State.find_or_initialize_by id: "7"
    estado2.name="Formulación2"
    estado2.order="2"
    estado2.municipio=mun2
    estado2.save
    states<<estado2

    estado3=State.find_or_initialize_by id: "8"
    estado3.name="Observado2"
    estado3.order="3"
    estado3.municipio=mun2
    estado3.save
    states<<estado3

    estado4=State.find_or_initialize_by id: "9"
    estado4.name="Licitación2"
    estado4.order="4"
    estado4.municipio=mun2
    estado4.save
    states<<estado4

    estado5=State.find_or_initialize_by id: "10"
    estado5.name="Ejecución2"
    estado5.order="5"
    estado5.municipio=mun2
    estado5.save
    states<<estado5

      
    mun2.save

    

    mun3=Municipio.find_or_initialize_by id: "3"
    mun3.name="Municipalidad de Nogales"
    estado1=State.find_or_initialize_by id: "11"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun3
    estado1.save
    states<<estado1

    estado2=State.find_or_initialize_by id: "12"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun3
    estado2.save
    states<<estado2

    estado3=State.find_or_initialize_by id: "13"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun3
    estado3.save
    states<<estado3

    estado4=State.find_or_initialize_by id: "14"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun3
    estado4.save
    states<<estado4

    estado5=State.find_or_initialize_by id: "15"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun3
    estado5.save
    states<<estado5

      
    mun3.save
    
    count=1
    states.each do |s|
        mun=Municipio.find_or_create_by(id: s.municipio.id)
        state=mun.states.find_or_create_by(id: s.id)
        task1=state.tasks.find_or_initialize_by(id: count)
        task1.name="tarea #{count%6} por defecto de estado #{s.id}"
        task1.desc="descripcion de tarea por defecto de estado #{s.id}"
        count=count+1
        task1.save

        task2=state.tasks.find_or_initialize_by(id: count)
        task2.name="tarea #{count%6} por defecto de estado #{s.id}"
        task2.desc="descripcion de tarea por defecto de estado #{s.id}"
        count=count+1
        task2.save

        task3=state.tasks.find_or_initialize_by(id: count)
        task3.name="tarea #{count%6} por defecto de estado #{s.id}"
        task3.desc="descripcion de tarea por defecto de estado #{s.id}"
        count=count+1
        task3.save

        task4=state.tasks.find_or_initialize_by(id: count)
        task4.name="tarea #{count%6} por defecto de estado #{s.id}"
        task4.desc="descripcion de tarea por defecto de estado #{s.id}"
        count=count+1
        task4.save

        task5=state.tasks.find_or_initialize_by(id: count)
        task5.name="tarea #{count%6} por defecto de estado #{s.id}"
        task5.desc="descripcion de tarea por defecto de estado #{s.id}"
        count=count+1
        task5.save

        task6=state.tasks.find_or_initialize_by(id: count)
        task6.name="tarea #{count%6} por defecto de estado #{s.id}"
        task6.desc="descripcion de tarea por defecto de estado #{s.id}"
        count=count+1
        task6.save
        
        
    end
    mun=Municipio.find_or_initialize_by( id: "1")
    user1=mun.users.find_or_initialize_by(login_mail: "nschmidtg@gmail.com")
    user1.login_name="Nicolas"
    user1.login_last_name="Schmidt"
    user1.login_pass = Digest::SHA256.base64digest("articuno")
    user1.role="secpla"
    user1.save

    zone1=Zone.find_or_initialize_by(id: "1")
    zone1.coords="-33.085 -80.930"
    zone1.name="pelambres"
    zone1.municipio=mun
    zone1.save

    zone2=Zone.find_or_initialize_by(id: "2")
    zone2.coords="-33.085 -80.930"
    zone2.name="Catemu"
    zone2.municipio=mun
    zone2.save

    
    mun2=Municipio.find_or_initialize_by( id: "1")
    user2=mun2.users.find_or_initialize_by(login_mail: "nicolassg@uc.cl")
    user2.login_name="Nicolas"
    user2.login_last_name="Schmidt"
    user2.login_pass = Digest::SHA256.base64digest("articuno2")
    user2.role="admin"

    user2.save
    #aca tienen que ir los datos del admin del equipo
    mem_tok="7fccb76f70cc1f8c993c67f16f16675b7852a06a8057a20f996063956b94091c"
    pub_key=ENV['PUBLIC_KEY']
    client = Trello::Client.new(
      :developer_public_key => pub_key,
      :member_token => mem_tok
    )
    #creo el webhook
    JSON.parse(client.put("/webhooks?idModel=5783f95e2dbc20dad889a3fb&callbackURL=http://gestion-municipal.herokuapp.com/new_board_createds?data=5783f95e2dbc20dad889a3fb|#{mem_tok}|#{pub_key}&description=primera descripcion del webhook del equipo: No priorizados"))

    # Roles posibles:
    # -admin (Crear municipios nuevos, enviar invitaciones a nuevos secpla)
    #     -secpla (crear y editar proyectos, crear y editar zonas, crear nuevos funcionarios, crear y editar tareas predeterminadas por estado)
    #         -alcalde (ver indicadores globales, ver indicadores de proyecto, filtrar por zonas)
    #         -concejal
    #         -funcionario
    


    redirect '/'
  end

  post '/new_board_createds', :auth => :none do
    puts params
    puts "******"
    parametros=params[:data].split('|')
    idModel=parametros[0]
    member_token=parametros[1]
    pub_key=parametros[2]
    puts idModel
    puts member_token
    puts pub_key

    client = Trello::Client.new(
      :developer_public_key => pub_key,
      :member_token => member_token
    )
    Trello.configure do |config|
      config.developer_public_key = pub_key
      config.member_token = member_token
    end
    org=Trello::Organization.find(idModel)
    boards=org.boards
    boards.each do |board|
        if(Board.find_by(board_id: board.id)==nil)
            begin
                User.all.each do |user|
                    Trello.configure do |config|
                      config.developer_public_key = ENV['PUBLIC_KEY']
                      config.member_token = user.member_token
                    end
                    client = Trello::Client.new(
                      :developer_public_key => pub_key,
                      :member_token => user.member_token
                    )
                    begin
                       
                        if(board.closed==false)
                            puts user.member_token
                            board.closed=true
                            nombre=board.name
                            board.name="¡No puede crear proyectos de esa forma! Conctáctese con su Director Secpla. El tablero #{nombre} "
                            board.update!
                            puts "#{board.id} cerrado"
                        end
                    rescue
                        puts "no se pudo"
                    end
                end
            rescue
                puts "#{board.id} ya estaba cerrado"
            end
        end
    end
    status 200
  end
end
