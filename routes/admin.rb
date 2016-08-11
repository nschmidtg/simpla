require 'trello'
class Ollert
  get '/admin', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin")
      if(@user.role=="secpla")
        respond_to do |format|
        format.html do
          flash[:succes] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect "/admin/municipio?id=#{@user.municipio.id}"
        end
      end
      end
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      @municipios = Municipio.all
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
      format.html { haml :admin }
      
    end
  end

  get '/admin/municipio', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:id]==@user.municipio.id.to_s))
        @municipio = Municipio.find_by(id: params[:id])
      else
        puts @user.municipio.id
        puts @user.role
        puts params[:id]
        puts "*********************************"
        puts (@user.role=="secpla" && params[:id]==@user.municipio.id.to_s)
        respond_to do |format|
          format.html do
            flash[:error] = "No tienes permiso para editar este municipio."
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
      format.html { haml :municipio }
      
    end
  end

  get '/admin/municipio/delete', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  @user.member_token
    end
    if(@user.role!="admin")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      @municipio = Municipio.find_by(id: params[:id_municipio])
      @municipio.organizations.each do |org|
        boards=Trello::Board.find(org.boards)
        boards.each do |board|
          begin
            JSON.parse(client.delete("/boards/#{board.id}/closed?value=true"))
          rescue
          end
        end
        begin
          JSON.parse(client.delete("/organizations/#{org.org_id}"))
        rescue
        end
      end

      @municipio.destroy
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
      flash[:succes] = "Municipio eliminado satisfactoriamente."
      redirect '/admin'
      
    end

  end

  get '/admin/municipio/launch', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token = @user.member_token
    end
    if(@user.role!="admin")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    
      if(@user.role=="admin")
        mun=Municipio.find_by(id: params[:mun_id])
        mun.launched="true"
        mun.save
        mun.organizations.each do |org|
          trello_org=Trello::Organization.find(org.org_id)
          mun.users.each do |user|
            if(user.role=="admin" || user.role=="secpla")
              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
            else
              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
            end
          end
        end
        mun.boards.each do |board|
          mun.users.each do |user|
            if(user.role=="admin" || user.role=="secpla")
              JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
            else
              JSON.parse(client.put("/boards/#{board.borad_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
            end
          end
        end
        
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
            redirect '/boards'
          end

          format.json { status 400 }
        end
      end
    
      # unless @user.nil?
      #   @user.member_token = nil
      #   @user.trello_name = nil
      #   @user.save
      # end

      # respond_to do |format|
      #   format.html do
      #     flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
      #     redirect '/boards'
      #   end

      #   format.json { status 400 }
      # end
    

    respond_to do |format|
      flash[:succes] = "Invitaciones enviadas satisfactoriamente."
      redirect "/admin"
      
    end

    
  end

  post '/admin/create_municipio', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token = @user.member_token
    end
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "No es administrador. No puede crear o editar municipios."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        nombre=params[:name]
        zonas=params[:zonas]
        edit=params[:edit]
        if(edit=="true")
          mun=Municipio.find_by(id: params[:id])
          mun.zones.each do |zone|
            if(!zonas.include?(zone.name))
              zone.destroy
            end
          end
        else
          if(@user.role=="admin")
            mun=Municipio.new
            mun.launched="false"
            o1=JSON.parse(client.post("/organizations?name=Urgentes&displayName=Urgentes&desc=#{nombre}"))
            puts o1
            org=Organization.find_or_initialize_by(org_id: o1["id"])
            org.name="Urgentes"
            org.municipio=mun
            org.save

            o1=JSON.parse(client.post("/organizations?name=No Priorizados&displayName=No Priorizados&desc=#{nombre}"))
            org=Organization.find_or_initialize_by(org_id: o1["id"])
            org.name="No Priorizados"
            org.municipio=mun
            org.save

            o1=JSON.parse(client.post("/organizations?name=Priorizados&displayName=Priorizados&desc=#{nombre}"))
            org=Organization.find_or_initialize_by(org_id: o1["id"])
            org.name="Priorizados"
            org.municipio=mun
            org.save

            estado1=State.new
            estado1.name="No iniciado"
            estado1.order="1"
            estado1.municipio=mun
            estado1.save

            estado2=State.new
            estado2.name="Formulación"
            estado2.order="2"
            estado2.municipio=mun
            estado2.save

            estado3=State.new
            estado3.name="Observado"
            estado3.order="3"
            estado3.municipio=mun
            estado3.save

            estado4=State.new
            estado4.name="Licitación"
            estado4.order="4"
            estado4.municipio=mun
            estado4.save

            estado5=State.new
            estado5.name="Ejecución"
            estado5.order="5"
            estado5.municipio=mun
            estado5.save
            mun.save
          end

        end
        mun.name=nombre
        mun.save
        
        zonas.each do |zone|
          if(!mun.zones.pluck(:name).include?(zone))
            z=Zone.new
            z.name=zone
            z.municipio=mun
            z.save
          end
          
        end
        
      else
        respond_to do |format|
          format.html do
            flash[:error] = "No tiene permiso para editar o crear Municipios."
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
          flash[:error] = "cacaHubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      if(edit=="true")
        flash[:succes] = "Municipio editado satisfactoriamente."
      else
        flash[:succes] = "Municipio creado satisfactoriamente."
      end
      redirect "/admin/municipio/users?mun_id=#{mun.id}"
      
    end

    
  end

  get '/admin/municipio/users', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin"  && @user.role!="secpla" )
      respond_to do |format|
        format.html do
          flash[:error] = "1Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
      else
        respond_to do |format|
          format.html do
            flash[:error] = "2Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
          flash[:error] = "3Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      format.html { haml :municipio_users }
      
    end

    
  end

  post '/admin/create_user', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id))

        edit=params[:edit]
        @mun=Municipio.find_by(id: params[:mun_id])
        if(edit=="true")
          new_user=User.find_by(id: params[:id])
        else
          new_user=User.new
        end
        new_user.login_name=params[:name]
        new_user.login_last_name=params[:last_name]
        new_user.login_mail=params[:mail]
        if(edit=="false")
          new_user.login_pass=Digest::SHA256.base64digest(params[:pass1])
        end
        if(params[:role]=="admin" && @user.role!="admin")
          respond_to do |format|
            format.html do
              flash[:error] = "No tienes permiso para dar este rol."
              redirect '/boards'
            end

            format.json { status 400 }
          end
        end
        new_user.role=params[:role]
        new_user.municipio=@mun
        new_user.save
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
            redirect '/admin'
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
          redirect '/admin'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
        format.html do
          flash[:succes] = "Usuario creado exitosamente"
          redirect "/admin/municipio/users?mun_id=#{@mun.id}"
        end

        format.json { status 400 }
      end

    
  end

  get '/admin/municipio/proyectos', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id))
        @mun=Municipio.find_by(id: params[:mun_id])
        @boards=@mun.boards

        
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
      format.html { haml :user }
      
    end
  end

  get '/admin/municipio/users/user', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id))
        @mun=Municipio.find_by(id: params[:mun_id])
        @new_user=User.find_by(id: params[:user_id])

        if(@new_user!=nil)
          if(@new_user.role=="admin" && @user.role!="admin")
            respond_to do |format|
              format.html do
                flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
                redirect '/boards'
              end

              format.json { status 400 }
            end
          end
        end
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
      format.html { haml :user }
      
    end

    
  end

  get '/admin/municipio/users/user/delete', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin"  && @user.role!="secpla" )
      respond_to do |format|
        format.html do
          flash[:error] = "No tiene permiso para eliminar usuarios."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id))
        @mun=Municipio.find_by(id: params[:mun_id])
        @new_user=@mun.users.find_by(id: params[:user_id])
        if(@new_user!=nil)
          @new_user.destroy
        end
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
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
          redirect '/admin'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      format.html do
        flash[:succes] = "Usuario eliminado exitosamente."

        redirect '/admin'
      end
      
    end
  end
end
