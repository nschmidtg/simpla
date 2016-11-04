class Ollert
  require 'socket'
  require 'mail'
  get '/', :auth => :none do
    if !@user.nil? && !@user.member_token.nil?
      if(@user.first_time=="true")
        redirect '/takeawalk'
      else
        if(@user.role=="concejal" || @user.role=="alcalde")
          redirect "/dashboard?mun_id=#{@user.municipio.id}"
        else
          redirect '/boards'
        end
      end
    end
    
    haml :landing
  end

  not_found do
    flash[:error] = "The page requested could not be found."
    redirect '/'
  end

  get '/takeawalk', :auth => :connected do
    @user.first_time="false"
    @user.save
    respond_to do |format|
      format.html { 
        haml :takeawalk 
      }
    end
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
            :domain               => ENV['DOMAIN_FORGOT'],
            :user_name            => ENV['MAIL_FORGOT'],
            :password             => ENV['PASS_FORGOT'],
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

      url="https://"+ENV['DOMAIN_FORGOT']+"/restore?hash=#{string}"
      Mail.deliver do
        from     ENV['MAIL_FORGOT']
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






end
