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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:id]==Municipio.find_by(id: @user.municipio.id).id))
        @municipio = Municipio.find_by(id: params[:id])
      else
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
post '/admin/create_municipio', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:id]==Municipio.find_by(id: @user.municipio.id).id))
        nombre=params[:name]
        zonas=params[:zonas]
        edit=params[:edit]
        if(edit=="true")
          mun=Municipio.find_by(id: params[:id])
          mun.zones.each do |zone|
            zone.destroy
          end
        else
          mun=Municipio.new
        end
        mun.name=nombre
        mun.save
        
        zonas.each do |zone|

          z=Zone.new
          z.name=zone
          z.municipio=mun
          z.save
          
        end
        if(edit=="false")
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

        puts mun.id
        puts Zone.find_by(id: mun.zones.last.id).municipio.id
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
      flash[:succes] = "Municipio eliminado satisfactoriamente."
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
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id))
        @mun=Municipio.find_by(id: params[:mun_id])
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
        new_user.login_pass=params[:pass]
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
