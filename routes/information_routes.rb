class Ollert
  require 'socket'
  require 'mail'

  not_found do
    flash[:error] = "The page requested could not be found."
    redirect '/'
  end

  #Definition of the root. 
  #Sends to landing, /boards, /dashboard or takeawalk depending on connected, first_time and role
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

  #Gets the view of the main features of the software. Shown only if it's the first time connecting
  get '/takeawalk', :auth => :connected do
    @user.first_time="false"
    @user.save
    respond_to do |format|
      format.html { 
        haml :takeawalk 
      }
    end
  end



  ###LOGIN###
  #Gets the mail and password from the login form and validates it. The it redirects to the Trello login
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



  ###FORGOT PASSWORD###
  #Form to restore password
  get '/forgot', :auth => :none do
    respond_to do |format|
      format.html { haml :forgot }
    end
  end

  #Gets the email from the restore password form and sends an email with a restore token
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

  #Gets the restore token, validates it and shows the form to change the password
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

  #Receive new password, validates it and change the password of the user
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



  ###CHANGE PASSWORD###
  #Gets the form to change password
  get '/change_pass_vol', :auth => :connected do
    respond_to do |format|
      format.html { haml :change_pass_vol }
    end
  end

  #Gets the new password and saves its hash
  post '/save_pass_vol', :auth => :connected do
    user=User.find_by(id: params[:user])
    if(user!=nil && params[:pass1]==params[:pass2])
      user.login_pass=Digest::SHA256.base64digest(params[:pass1])
      user.save
      flash[:success] = "Contraseña cambiada exitosamente."
      redirect '/'
    else
      flash[:error] = "El usuario no existe o las contraseñas no coinciden."
      redirect '/'
    end
  end




  ###INFORMATION###
  #Get the view to explain what are the default tasks
  get '/predet', :auth => :connected do
    respond_to do |format|
      format.html { haml :predet }
    end
  end

end
