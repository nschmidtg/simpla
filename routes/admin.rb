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
        @municipios = Municipio.where(id: @user.municipio.id)
      else
        @municipios = Municipio.all
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
      flash[:success] = "Municipio eliminado satisfactoriamente."
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
    if(@user.role!="admin" && @user.role!="secpla")
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
      flash[:success] = "Fondo eliminado satisfactoriamente."
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
            org.add_members(client,request.host)
          end
          mun.boards.each do |board|
            board.add_members(client,request.host)         
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
    
      mun=Municipio.find_by(id: params[:mun_id])
      mun.launched="true"
      mun.save

    respond_to do |format|
      flash[:success] = "Invitaciones enviadas satisfactoriamente."
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
        ubicacion=params[:zona]
        edit=params[:edit]
        if(edit=="true")
          #Si edito, sólo cambio la descripción de la organización en las 3 org.
          mun=Municipio.find_by(id: params[:id])
          orgs=mun.organizations.each do |org|
            JSON.parse(client.put("/organizations/#{org.org_id}/desc?value=#{nombre}"))
          end
        else
          #crear el municipio
          if(@user.role=="admin")
            #sólo si es admin puede crear el municipio
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


            t1=Tipo.new
            t1.name="Agua Potable y Alcantarillado"
            t1.municipio=mun
            t1.save

            t2=Tipo.new
            t2.name="Cultura, patrimonio y turismo"
            t2.municipio=mun
            t2.save

            t3=Tipo.new
            t3.name="Telecomunicaciones"
            t3.municipio=mun
            t3.save

            t4=Tipo.new
            t4.name="Seguridad"
            t4.municipio=mun
            t4.save

            t5=Tipo.new
            t5.name="Deportes"
            t5.municipio=mun
            t5.save

            t6=Tipo.new
            t6.name="Energía"
            t6.municipio=mun
            t6.save

            t7=Tipo.new
            t7.name="Infraestructura vial"
            t7.municipio=mun
            t7.save

            t8=Tipo.new
            t8.name="Medioambiente"
            t8.municipio=mun
            t8.save

            t9=Tipo.new
            t9.name="Espacio público"
            t9.municipio=mun
            t9.save

            t10=Tipo.new
            t10.name="Salud"
            t10.municipio=mun
            t10.save

            t11=Tipo.new
            t11.name="Infraestructura comunitaria"
            t11.municipio=mun
            t11.save

            t12=Tipo.new
            t12.name="Vivienda"
            t12.municipio=mun
            t12.save

            t13=Tipo.new
            t13.name="Educación"
            t13.municipio=mun
            t13.save

            



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
            estado1.name="En formulación"
            estado1.order=1
            estado1.municipio=mun
            estado1.save

            estado2=State.new
            estado2.name="Ingresado"
            estado2.order=2
            estado2.municipio=mun
            estado2.save

            estado3=State.new
            estado3.name="Observado"
            estado3.order=3
            estado3.municipio=mun
            estado3.save

            estado4=State.new
            estado4.name="Con aprobación técnica"
            estado4.order=4
            estado4.municipio=mun
            estado4.save

            estado5=State.new
            estado5.name="Con recursos aprobados"
            estado5.order=5
            estado5.municipio=mun
            estado5.save

            estado6=State.new
            estado6.name="Preparación de licitación"
            estado6.order=6
            estado6.municipio=mun
            estado6.save

            estado7=State.new
            estado7.name="Evaluación y adjudicación de propuestas"
            estado7.order=7
            estado7.municipio=mun
            estado7.save

            estado8=State.new
            estado8.name="En ejecución"
            estado8.order=8
            estado8.municipio=mun
            estado8.save
            
            estado9=State.new
            estado9.name="Finalizado"
            estado9.order=9
            estado9.municipio=mun
            estado9.save

            estado10=State.new
            estado10.name="Descartado"
            estado10.order=10
            estado10.municipio=mun
            estado10.save


            #Tareas predeterminadas para Municipal de Diseño. Formulación.
            task1=Task.new
            task1.name="Visación de entidad relacionada (Educación, Salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura o programa arquitectónico"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f1
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Documento que certifique disponibilidad presupuestaria"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Crear cuenta (enviar Decreto a finanzas)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f1
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f1
            task1.checked="true"
            task1.save






            #Tareas predeterminadas para FNDR de Diseño. Formulación.
            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura o programa arquitectónico"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Descripción y justificación del proyecto"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Cronograma de inversión"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f2
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f2
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f2
            task1.checked="true"
            task1.save

            #Tareas predeterminadas para FRIL de Diseño. Formulación. TAMBIEN ES EL DEFAULT DISEÑO
            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura o programa arquitectónico"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f3
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f3
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f3
            task1.checked="true"
            task1.save

            #Tareas predeterminadas para MUNICIPAL de EJECUCIÓN. Formulación.
            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de especialidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Estudio de suelo"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f4
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Documento que certifique disponibilidad presupuestaria"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Crear cuenta (enviar Decreto a finanzas)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f4
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f4
            task1.checked="true"
            task1.save


            #Tareas predeterminadas para FNDR de EJECUCIÓN. Formulación.
            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de especialidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Estudio de suelo"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Descripción y justificación del proyecto"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Cronograma de inversión"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f5
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f5
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f5
            task1.checked="true"
            task1.save


            #Tareas predeterminadas para FRIL de EJECUCIÓN. Formulación.
            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de especialidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Estudio de suelo"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f6
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f6
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f6
            task1.checked="true"
            task1.save

            #Tareas predeterminadas para PMU de EJECUCIÓN. Formulación. También es casi default para la creación de fondos, excepto por la fichi idi, que es opcional en vez de obligatoria
            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de especialidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Estudio de suelo"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f7
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Crear cuenta (enviar Decreto a finanzas)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f7
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f7
            task1.checked="true"
            task1.save

            #Tareas predeterminadas para PMB de EJECUCIÓN. Formulación.
            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de especialidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Estudio de suelo"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=f8
            task1.checked="true"
            task1.save

            #Licitacion1
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Crear cuenta (enviar Decreto a finanzas)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=f8
            task1.checked="true"
            task1.save

            #Licitación 2
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=f8
            task1.checked="true"
            task1.save

            mun.save
          end

        end
        #Independiente de si creo o edito, asigno el nombre, coordenadas y zonas al municipio
        mun.name=nombre
        mun.coords=ubicacion
        mun.save

        zonas.each do |zone_id,zone_name|
          if(!zone_id.include?("nuevo"))
            z=Zone.find_or_initialize_by(id: zone_id)
            z.name=zone_name.to_s
            z.municipio=mun
            z.save
          else
            z=Zone.new
            z.name=zone_name.to_s
            z.municipio=mun
            z.save
          end
        end
        mun.zones.each do |mun_zone|
          esta=false
          zonas.each do |zone_id,zone_name|
            if(zone_id.include?("nuevo"))
              esta=true
            end
            if(zone_id==mun_zone.id.to_s)
              esta=true
            end
          end
          if(esta==false)
            mun_zone.destroy
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
          flash[:error] = "Hubo un error en la conexión con Trello. Por favor pruebe de nuevo."
          redirect '/'
        end

        format.json { status 400 }
      end
    end

    respond_to do |format|
      if(edit=="true")
        flash[:success] = "Municipio editado satisfactoriamente."
        redirect "/admin"
      else
        flash[:success] = "Municipio creado satisfactoriamente."
        redirect "/admin"
      end
      
      
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
        flash[:success] = "Estado eliminado exitosamente."
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
        new_user.login_name=params[:name].gsub(" ","")
        new_user.login_last_name=params[:last_name].gsub(" ","")
        new_user.login_mail=params[:mail].downcase
        if(edit=="false")
          new_user.login_pass=Digest::SHA256.base64digest(params[:pass1])
          new_user.role=params[:role]

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
        new_user.save
        if(new_user.role!=params[:role] && new_user.trello_id!=nil)
          #Estoy editando el rol de un usuario que ya tenia cuenta en Ollert
          if(new_user.municipio.launched=="true")
            new_user.role=params[:role]
            if(new_user.role=="admin" || new_user.role=="secpla")
              new_user.municipio.organizations.each do |org|
                begin
                  JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=admin"))
                rescue => error
                  puts error
                end
              end
              new_user.municipio.boards.each do |board|
                begin
                  JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=admin"))
                rescue => error
                  puts error
                end
              end
            elsif(new_user.role=="funcionario")
              puta "hola"
              new_user.municipio.organizations.each do |org|
                begin
                  JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=normal"))
                rescue => error
                  puts error
                end
              end
              new_user.municipio.boards.each do |board|
                begin
                  JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{new_user.login_mail}&fullName=#{new_user.login_name} #{new_user.login_last_name}&type=normal"))
                rescue => error
                  puts error
                end
              end
            else
              new_user.municipio.organizations.each do |org|
                begin
                  JSON.parse(client.delete("/organizations/#{org.org_id}/members/#{new_user.trello_id}"))
                rescue => error
                  puts error
                end
              end
              new_user.municipio.boards.each do |board|
                begin
                  new_user.boards.delete(board)
                  JSON.parse(client.delete("/boards/#{board.board_id}/members/#{new_user.trello_id}"))
                rescue => error
                  puts error
                end
              end
              puts "se sacó al concejal o alcalde de los tableros y equipos"
              secpla=new_user.municipio.users.find_by(role: "secpla")
              if(secpla!=nil)
                new_user.member_token=new_user.municipio.users.find_by(role: "secpla").member_token
              end
            end
          end
        else
          puts "aca 2"+params[:role]
          new_user.role=params[:role]
          if(new_user.role=="alcalde"|| new_user.role=="concejal")
            #sacar a este loco de los tableros
            if(edit=="true")
              new_user.municipio.organizations.each do |org|
                begin
                  JSON.parse(client.delete("/organizations/#{org.org_id}/members/#{new_user.trello_id}"))
                rescue => error
                  puts error
                end
              end
              new_user.municipio.boards.each do |board|
                begin
                  new_user.boards.delete(board)
                  JSON.parse(client.delete("/boards/#{board.board_id}/members/#{new_user.trello_id}"))
                rescue => error
                  puts error
                end
              end
              puts "se sacó al concejal o alcalde de los tableros y equipos"
            end
            secpla=new_user.municipio.users.find_by(role: "secpla")
            if(secpla!=nil)
              new_user.member_token=new_user.municipio.users.find_by(role: "secpla").member_token
            end
          else
            #Acá se llega cuando un concejal o alcalde pasa a ser funcionario o secpla
            if(edit=="true")
              mun=new_user.municipio
              if(mun.launched=="true")
                Thread.new do
                  mun.organizations.each do |org|
                    org.add_members(client,request.host)
                  end
                  mun.boards.each do |board|
                    board.add_members(client,request.host)         
                  end
                end
              end
            end
          end
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
          flash[:success] = "Usuario creado exitosamente"
          redirect "/admin/municipio/users?mun_id=#{@mun.id}"
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
          flash[:success] = "Estado creado exitosamente"
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
          new_fondo.custom="true"
        else
          new_fondo=Fondo.new
          if(params[:etapa]=="diseno")
            #Tareas predeterminadas para FRIL de Diseño. Formulación. TAMBIEN ES EL DEFAULT DISEÑO
            estado1=@mun.states[0]

            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura o programa arquitectónico"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            #Licitacion1
            estado6=@mun.states[5]
            
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            #Licitación 2
            estado7=@mun.states[6]

            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save
          elsif(params[:etapa]=="ejecucion")
            estado1=@mun.states[0]

            task1=Task.new
            task1.name="Certificado de compromiso de operación y mantención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Certificado de propiedad o BNUP"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visación de entidad relacionada (Educ, salud, Serviu)"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de especialidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad eléctrica"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Factibilidad sanitaria"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Estudio de suelo"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Cotizaciones que respalden los montos solicitados"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Visitar terreno para identificar necesidades"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Acta de participación ciudadana"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Oficio conductor del alcalde"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Ficha IDI o equivalente"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="false"
            task1.save

            task1=Task.new
            task1.name="Planos de ubicación"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de emplazamiento"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Planos de arquitectura"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Presupuesto itemizado por partida"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Especificaciones técnicas"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Fotografías antes de la intervención"
            task1.desc=""
            task1.state=estado1
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            #Licitacion1
            estado6=@mun.states[5]
            task1=Task.new
            task1.name="Elaborar bases de licitación"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Decreto aprueba bases"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Subir documentos al sistema (bases, EE.TT., presupuesto, planos)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Definir comisiónes de apertura y evaluación "
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar Decreto nombra comisión"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Revisar bases de licitación (visto bueno)"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Publicar licitación en Mercado Público"
            task1.desc=""
            task1.state=estado6
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            #Licitación 2
            estado7=@mun.states[6]
            task1=Task.new
            task1.name="Visita a terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Responder preguntas"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de apertura)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Evaluar ofertas (comisión de evaluación)"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar Decreto de adjudicación o deseerción"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Generar orden de compra"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Elaborar contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Gestionar firma de contrato"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Devolver boletas de garantía"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save

            task1=Task.new
            task1.name="Enviar antecedentes a DOM para entrega de terreno"
            task1.desc=""
            task1.state=estado7
            task1.fondo=new_fondo
            task1.checked="true"
            task1.save
          end
        end
        new_fondo.name=params[:name]
        if(params[:etapa]!=nil)
          new_fondo.etapa=params[:etapa]
        end
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
          flash[:success] = "Estado creado exitosamente"
          redirect "/admin/municipio/fondos?mun_id=#{@mun.id}"
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
          if(params[:checked].to_s=="on")
            new_task.checked="true"
          else
            new_task.checked="false"
          end
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
          flash[:success] = "Estado creado exitosamente"
          redirect "/admin/municipio/states/tasks?mun_id=#{@mun.id}&state_id=#{@state.id}&fondo_id=#{@fondo.id}"
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
        flash[:success] = "Tarea eliminado exitosamente."

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
        flash[:success] = "Usuario eliminado exitosamente."

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
