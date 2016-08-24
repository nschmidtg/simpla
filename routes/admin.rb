require 'trello'
class Ollert
  get '/admin', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin" && @user.role!="secpla" )
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="secpla")
        @municipios = @user.municipio
      end
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
        boards=Trello::Organization.find(org.org_id).boards
        boards.each do |board|
          begin
            JSON.parse(client.put("/boards/#{board.id}/closed?value=true"))
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

  get '/admin/municipio/fondos/fondo/delete', :auth => :connected do
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
      @municipio = Municipio.find_by(id: params[:mun_id])
      @fondo=Fondo.find_by(id: params[:fondo_id])
      if(@fondo.municipio.id==@municipio.id)
        @fondo.destroy
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
      flash[:succes] = "Fondo eliminado satisfactoriamente."
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
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/boards'
        end
      end
    end
    
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==@user.municipio.id.to_s))
        mun=Municipio.find_by(id: params[:mun_id])
        Thread.new do
          mun.organizations.each do |org|
            data=JSON.parse(client.get("/organizations/#{org.org_id}/members?filter=admins"))
            admin_ids=Array.new()
            data.each do |admin|
              admin_ids<<admin["id"]
            end
            data=JSON.parse(client.get("/organizations/#{org.org_id}/members?filter=normal"))
            normal_ids=Array.new()
            data.each do |normal|
              normal_ids<<normal["id"]
            end

            mun.users.each do |user|
              if(user.trello_id!=nil)
                if(user.role=="admin" || user.role=="secpla")
                  if(!admin_ids.include?(user.trello_id))
                    begin
                      JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
                     rescue
                      JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                     end
                  end
                else
                  if(!normal_ids.include?(user.trello_id))
                    begin
                      JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
                    rescue
                    end
                  end
                end
              else
                data=JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                data=JSON.parse(client.get("/members/#{user.login_mail}"))
                aux=User.find_by(trello_id: data["id"])
                if(aux==nil)
                  user.trello_id=data["id"]
                  user.save                  
                end
              
                if(user.role=="admin" || user.role=="secpla")
                  begin
                    JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
                  rescue
                  end
                end
              end
            end
          end
          mun.boards.each do |board|
            data=JSON.parse(client.get("/boards/#{board.board_id}/members?filter=admins"))
            admin_ids=Array.new()
            data.each do |admin|
              admin_ids<<admin["id"]
            end
            data=JSON.parse(client.get("/boards/#{board.board_id}/members?filter=normal"))
            normal_ids=Array.new()
            data.each do |normal|
              normal_ids<<normal["id"]
            end
            mun.users.each do |user|
              if(user.trello_id!=nil)
                if(user.role=="admin" || user.role=="secpla")
                  if(!admin_ids.include?(user.trello_id))
                    begin
                      JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
                    rescue
                      JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                    end
                  end
                else
                  if(!normal_ids.include?(user.trello_id))
                    begin
                      JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
                     rescue
                      JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                     end
                  end
                end
              else
                puts "++++No debería entrar nunca acá, porque ya se asignó el trello id++++"
              end
            end
          end
          mun.launched="true"
          mun.save
        end
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
            mun=Municipio.find_by(id: params[:mun_id])
            mun.launched="false"
            mun.save
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
      mun=Municipio.find_by(id: params[:mun_id])
      mun.launched="true"
      mun.save

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
            o1=JSON.parse(client.post("/organizations?name=1. Urgentes&displayName=1. Urgentes&desc=#{nombre}"))
            #puts o1
            org=Organization.find_or_initialize_by(org_id: o1["id"])
            org.name="1. Urgentes"
            org.municipio=mun
            org.save

            o1=JSON.parse(client.post("/organizations?name=3. No Priorizados&displayName=3. No Priorizados&desc=#{nombre}"))
            org=Organization.find_or_initialize_by(org_id: o1["id"])
            org.name="3. No Priorizados"
            org.municipio=mun
            org.save

            o1=JSON.parse(client.post("/organizations?name=2. Priorizados&displayName=2. Priorizados&desc=#{nombre}"))
            org=Organization.find_or_initialize_by(org_id: o1["id"])
            org.name="2. Priorizados"
            org.municipio=mun
            org.save

            f1=Fondo.new
            f1.name="Municipal"
            f1.etapa="diseno"
            f1.custom="false"
            f1.municipio=mun
            f1.save

            f2=Fondo.new
            f2.name="FNDR"
            f2.etapa="diseno"
            f2.custom="false"
            f2.municipio=mun
            f2.save

            f3=Fondo.new
            f3.name="FRIL"
            f3.etapa="diseno"
            f3.custom="false"
            f3.municipio=mun
            f3.save

            f4=Fondo.new
            f4.name="Municipal"
            f4.etapa="ejecucion"
            f4.custom="false"
            f4.municipio=mun
            f4.save

            f5=Fondo.new
            f5.name="FNDR"
            f5.etapa="ejecucion"
            f5.custom="false"
            f5.municipio=mun
            f5.save

            f6=Fondo.new
            f6.name="FRIL"
            f6.etapa="ejecucion"
            f6.custom="false"
            f6.municipio=mun
            f6.save

            f7=Fondo.new
            f7.name="PMU"
            f7.etapa="ejecucion"
            f7.custom="false"
            f7.municipio=mun
            f7.save

            f8=Fondo.new
            f8.name="PMB"
            f8.etapa="ejecucion"
            f8.custom="false"
            f8.municipio=mun
            f8.save
            

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


            task1=Task.new
            task1.name="tarea por defecto de No iniciado FNDR Ejecucion"
            task1.desc="desc de t1"
            task1.state=estado1
            task1.fondo=f5
            task1.save


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

  get '/admin/municipio/states/tasks', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @state=State.find_by(id: params[:state_id])
        @fondo=Fondo.find_by(id: params[:fondo_id])
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Está tratando de editar un municipio que no es el suyo."
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
      format.html { haml :municipio_states_tasks }
      
    end

    
  end

  get '/admin/municipio/states/tasks/task', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @state=State.find_by(id: params[:state_id])
        @task=Task.find_by(id: params[:task_id])
        @fondo=Fondo.find_by(id: params[:fondo_id])
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
      format.html { haml :task }
      
    end

    
  end

  get '/admin/municipio/fondos/fondo', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @fondo=Fondo.find_by(id: params[:fondo_id])
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
      format.html { haml :fondo }
      
    end

    
  end

  get '/admin/municipio/fondos/states', :auth => :connected do
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
        @fondo=Fondo.find_by(id: params[:fondo_id])
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Está tratando de editar un municipio que no es el suyo."
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
      format.html { haml :municipio_states }
      
    end

    
  end

  get '/admin/municipio/states/state', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @state=State.find_by(id: params[:state_id])
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
      format.html { haml :state }
      
    end

    
  end

  get '/admin/municipio/states/state/delete', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin"  && @user.role!="secpla" )
      respond_to do |format|
        format.html do
          flash[:error] = "No tiene permiso para eliminar estados."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @new_state=@mun.states.find_by(id: params[:state_id])
        if(@new_state!=nil)
          @new_state.destroy
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
        flash[:succes] = "Estado eliminado exitosamente."
        redirect '/admin'
      end
      
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))

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
        
        new_user.municipio=@mun
        if(new_user.role!=params[:role] && new_user.trello_id!=nil)
          #Estoy editando el rol de un usuario que ya tenia cuenta en Ollert
          new_user.role=params[:role]
          if(new_user.role=="admin" || new_user.role=="secpla")
            new_user.municipio.organizations.each do |org|
              begin
                JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=admin"))
              rescue
              end
            end
            new_user.municipio.boards.each do |board|
              begin
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=admin"))
              rescue
              end
            end
          else
            new_user.municipio.organizations.each do |org|
              begin
                JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=normal"))
              rescue
              end
            end
            new_user.municipio.boards.each do |board|
              begin
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=normal"))
              rescue
              end
            end
          end
        else
          new_user.role=params[:role]
        end
        new_user.save
        if(edit=="false")
          @mun.launched="false"
        end
        @mun.save
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
          redirect "/admin"
        end
      end

    
  end

  post '/admin/create_state', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))

        edit=params[:edit]
        @mun=Municipio.find_by(id: params[:mun_id])
        if(edit=="true")
          new_state=State.find_by(id: params[:id])
        else
          new_state=State.new
        end
        new_state.name=params[:name]
        new_state.order=params[:order]
        new_state.municipio=@mun
        new_state.save
        @mun.save
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
          flash[:succes] = "Estado creado exitosamente"
          redirect "/admin"
        end
      end

    
  end

  post '/admin/create_fondo', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))

        edit=params[:edit]
        @mun=Municipio.find_by(id: params[:mun_id])
        if(edit=="true")
          new_fondo=Fondo.find_by(id: params[:id])
        else
          new_fondo=Fondo.new
        end
        new_fondo.name=params[:name]
        new_fondo.etapa=params[:etapa]
        new_fondo.municipio=@mun
        new_fondo.save
        @mun.save
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
          flash[:succes] = "Estado creado exitosamente"
          redirect "/admin"
        end
      end

    
  end

  post '/admin/create_task', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))

        edit=params[:edit]
        @mun=Municipio.find_by(id: params[:mun_id])
        @fondo=Fondo.find_by(id: params[:fondo_id])
        @state=@mun.states.find_by(id: params[:state_id])
        if(@state!=nil)
          if(edit=="true")
            new_task=Task.find_by(id: params[:id])
          else
            new_task=Task.new
          end
          new_task.name=params[:name]
          new_task.desc=params[:desc]
          new_task.state=@state
          new_task.fondo=@fondo
          new_task.save
          @state.save
        else
          respond_to do |format|
            format.html do
              flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
              redirect '/admin'
            end

            format.json { status 400 }
          end
        end
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
          flash[:succes] = "Estado creado exitosamente"
          redirect "/admin"
        end
      end

    
  end

  get '/admin/municipio/proyecto', :auth => :connected do
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
  end

  get '/admin/municipio/proyectos', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  @user.member_token
    end
    if(@user.role!="admin" && @user.role!="secpla")
      respond_to do |format|
        format.html do
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/admin'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @boards=@mun.boards

        
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
      format.html { haml :admin_boards }
      
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
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

  
  get '/admin/municipio/states/tasks/task/delete', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    if(@user.role!="admin"  && @user.role!="secpla" )
      respond_to do |format|
        format.html do
          flash[:error] = "No tiene permiso para eliminar tareas."
          redirect '/boards'
        end
      end
    end
    begin
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @new_task=Task.find_by(id: params[:task_id])
        if(@new_task!=nil)
          @new_task.destroy
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
        flash[:succes] = "Tarea eliminado exitosamente."

        redirect '/admin'
      end
      
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
        @mun=Municipio.find_by(id: params[:mun_id])
        @new_user=@mun.users.find_by(id: params[:user_id])
        if(@new_user!=nil)
          boards=@new_user.municipio.boards
          boards.each do |board|
            begin
              JSON.parse(client.delete("/boards/#{board.board_id}/members/#{@new_user.trello_id}"))
            rescue
            end
          end
          orgs=@new_user.municipio.organizations
          orgs.each do |org|
            begin
              JSON.parse(client.delete("/organizations/#{org.org_id}/members/#{@new_user.trello_id}"))
            rescue
            end
          end
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

  get '/admin/municipio/fondos', :auth => :connected do
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
      if(@user.role=="admin" || (@user.role=="secpla" && params[:mun_id]==Municipio.find_by(id: @user.municipio.id).id.to_s))
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
      format.html { haml :municipio_fondos }
      
    end

    
  end
end
