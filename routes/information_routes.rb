class Ollert
  require 'socket'
  require 'mail'
  get '/', :auth => :none do
    if !@user.nil? && !@user.member_token.nil?
      if(@user.role=="concejal" || @user.role=="alcalde")
        redirect "/dashboard?mun_id=#{@user.municipio.id}"
      else
        redirect '/boards'
      end
    end
    
    haml :landing
  end

  not_found do
    flash[:error] = "The page requested could not be found."
    redirect '/'
  end

  post '/change_pass', :auth => :none do
    user=User.find_by(restore_pass: params[:hash])
    if(user!=nil && params[:pass1]==params[:pass2])
      if((Time.now-(user.restore_pass_generated.to_time))<300)
        user.login_pass=Digest::SHA256.base64digest(params[:pass1])
        user.save
        flash[:success] = "Contraseña cambiada exitosamente."
        redirect '/'
      else
        flash[:error] = "Han transcurrido más de 5 minutos desde el intento de reestablecer contraseña. Vuelva a intentarlo."
        redirect '/forgot'
      end
    else
      flash[:error] = "El usuario no existe o las contraseñas no coinciden."
      redirect '/'
    end
  end
  

  get '/forgot', :auth => :none do
    respond_to do |format|
      format.html { haml :forgot }
    end
  end

  get '/restore', :auth => :none do
    @hash=params[:hash]

    user=User.find_by(restore_pass: @hash)
    if(user!=nil)
      if((Time.now-(user.restore_pass_generated.to_time))<300)
        respond_to do |format|
        format.html { haml :restore }
      end
      else
        flash[:error] = "Han transcurrido más de 5 minutos desde el intento de reestablecer contraseña. Vuelva a intentarlo."
        redirect '/'
      end
    else
      flash[:error] = "El usuario no existe."
      redirect '/'
    end
  end

  post '/forgot_mail', :auth => :none do
    user=User.find_by(login_mail: params[:mail])
    if(user!=nil)
      options = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'gestion-municipal.herokuapp.com',
            :user_name            => 'sistema.gestion.cpp@gmail.com',
            :password             => 'subdipro2016',
            :authentication       => 'plain',
            :enable_starttls_auto => true  }
      Mail.defaults do
        delivery_method :smtp, options
      end

      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      string = (0...50).map { o[rand(o.length)] }.join
      user.restore_pass=string
      user.restore_pass_generated=Time.now;
      user.save

      url="https://gestion-municipal.herokuapp.com/restore?hash=#{string}"
      Mail.deliver do
        from     'sistema.gestion.cpp@gmail.com'
        to       user.login_mail
        subject  'Restablecer Contraseña'
        body     "Estimado, para reestablecer su contraseña ingrese al siguiente link: #{url}"
      end
      flash[:success] = "Se ha enviado un correo a #{user.login_mail} con las instrucciones para reestablecer la contraseña."
      redirect '/'
    else
      flash[:error] = "El correo electrónico indicado no se encuentra registrado."
      redirect '/forgot'
    end
  end

  post '/authorize', :auth => :none do
    require 'digest'
    mail=params[:mail]
    password=params[:password]
    user= User.find_by(login_mail: mail)
    if(user!=nil)
      hash=Digest::SHA256.base64digest password
      if(hash==user.login_pass)     
        respond_to do |format|
          format.html { haml :authorize }
        end
      else
        flash[:error] = "Contraseña no válida"
        redirect '/'
      end
    else

      flash[:error] = "Correo no registrado"
      redirect '/'
    
    end
    
  end



  get '/seed', :auth => :none do

    

    user1=User.find_or_initialize_by(login_mail: "sistema.gestion.cpp@gmail.com")
    user1.login_name="Admin"
    user1.login_last_name="CPP"
    user1.login_pass = Digest::SHA256.base64digest("subdipro2016")
    user1.role="admin"
    user1.save


    #creo el webhook
    #JSON.parse(client.put("/webhooks?idModel=5783f95e2dbc20dad889a3fb&callbackURL=http://gestion-municipal.herokuapp.com/new_board_createds?data=5783f95e2dbc20dad889a3fb|#{mem_tok}|#{pub_key}&description=primera descripcion del webhook del equipo: 3. No priorizados"))

   


    redirect '/'
  end

  post '/virtual_member', :auth => :none do
    
    parametros=params[:data].split('|')
    idModel=parametros[0]
    board_id=parametros[1]
    member_token=parametros[2]
    pub_key=parametros[3]
    puts idModel
    puts board_id
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
    begin
      puts "ME LLAMARON!!"
    rescue => error
      puts error
    end
  end

  # post '/new_board_createds', :auth => :none do
  #   #este es el método al que llamaba el webhook
  #   puts params
  #   puts "******"
  #   parametros=params[:data].split('|')
  #   idModel=parametros[0]
  #   member_token=parametros[1]
  #   pub_key=parametros[2]
  #   puts idModel
  #   puts member_token
  #   puts pub_key

  #   client = Trello::Client.new(
  #     :developer_public_key => pub_key,
  #     :member_token => member_token
  #   )
  #   Trello.configure do |config|
  #     config.developer_public_key = pub_key
  #     config.member_token = member_token
  #   end
  #   org=Trello::Organization.find(idModel)
  #   boards=org.boards
  #   boards.each do |board|
  #       if(Board.find_by(board_id: board.id)==nil)
  #           begin
  #               User.all.each do |user|
                    
  #                   client = Trello::Client.new(
  #                     :developer_public_key => pub_key,
  #                     :member_token => user.member_token
  #                   )
  #                   begin
                       
  #                       if(board.closed==false)
  #                           JSON.parse(client.put("/boards/#{board.id}?closed=true&name=No tiene autorización para crear tableros desde Trello. Contáctese con su Director Secpla. El tablero "))
  #                           JSON.parse(client.put("/webhooks?idModel=#{board.id}&callbackURL=http://gestion-municipal.herokuapp.com/new_board_createds?data=5783f95e2dbc20dad889a3fb|#{member_token}|#{pub_key}&description=primera descripcion del webhook del equipo: 3. No priorizados"))

  #                           puts user.member_token
                            
  #                           puts "#{board.id} cerrado"
  #                       end
  #                   rescue
  #                       puts "no se pudo"
  #                   end
  #               end
  #           rescue
  #               puts "#{board.id} ya estaba cerrado"
  #           end
  #       end
  #   end
  #   status 200
  # end

  get '/prueba', :auth => :none do
    puts "HOLA1!"
    puts request.host
    redirect '/'
    
  end
  # get '/prueba', :auth => :none do
  #   client = Trello::Client.new(
  #     :developer_public_key => "d362373a44e62ddcbb30a60418a99f41",
  #     :member_token => "23fdcebf89b98d1542b4157091551fcaab03a063cdf3a784bdcac0f1bab8a5fb"
  #   )
  #   Trello.configure do |config|
  #     config.developer_public_key = ENV['PUBLIC_KEY']
  #     config.member_token =  params['token']
  #   end
  #   JSON.parse(client.put("/boards/57a8d6365a77c2b4744e466a/members?email=mjcoloma@uc.cl&fullName=Nico"))

  # end






end
