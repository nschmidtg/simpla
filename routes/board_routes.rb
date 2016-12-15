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
  get '/predet', :auth => :connected do
    respond_to do |format|
      format.html { haml :predet }
    end
  end

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

  post '/dashboard/raport.xls', :auth => :connected do
      require 'zip/zip'
      require 'axlsx'

      client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  @user.member_token
    end
  

      @mun=@user.municipio
      @mun_id=@mun.id
      @boards=@mun.boards.and(
        @mun.boards.where(closed:"false").selector,
        @mun.boards.where(:current_state.ne => @mun.states.all[8].name).selector,
        @mun.boards.where(:current_state.ne => @mun.states.all[9].name).selector
        )
      @title="Indicadores de Gestión"
      @valores=Array.new()
      @sizes=Array.new()
      @fondos=Array.new()
      @zones=Array.new()
      @count=Array.new()
      count=0
      @mun.organizations.each do |org|
        if(org.name=="1. Urgentes")
          @count[0]=@boards.where(organization: org).count
        elsif(org.name=="2. Priorizados")
          @count[1]=@boards.where(organization: org).count
        elsif(org.name=="3. No Priorizados")
          @count[2]=@boards.where(organization: org).count
        end
      end
      i=0
      
      @big_total=0

      @total1 = @boards.where(current_state: /.*#{@mun.states[0].name}.*/).count
      @total2 = @boards.where(current_state: /.*#{@mun.states[1].name}.*/).count
      @total3 = @boards.where(current_state: /.*#{@mun.states[2].name}.*/).count
      puts @total1.to_s+" "+@total2.to_s+" "+@total3.to_s
      @stotal1 = @total1+@total2+@total3
      puts @stotal1
      @big_total=@big_total+@stotal1
      puts @big_total
      @total4 = @boards.where(current_state: /.*#{@mun.states[3].name}.*/).count
      @total5 = @boards.where(current_state: /.*#{@mun.states[4].name}.*/).count
      @stotal2 = @total4+@total5
      @big_total=@big_total+@stotal2
      @total6 = @boards.where(current_state: /.*#{@mun.states[5].name}.*/).count
      @total7 = @boards.where(current_state: /.*#{@mun.states[6].name}.*/).count
      @stotal3 = @total6+@total7
      @big_total=@big_total+@stotal3
      @total8 = @boards.where(current_state: /.*#{@mun.states[7].name}.*/).count
      @big_total=@big_total+@total8
      @total9 = @boards.where(current_state: nil).count+@boards.where(current_state: "").count
      @big_total=@big_total+@total9
      puts @big_total



      p=Axlsx::Package.new
      workbook=p.workbook
      workbook.styles do |s|
        #heading = s.add_style alignment: {horizontal: :center}, b: true, sz: 18, bg_color: "0066CC", fg_color: "FF"
        heading = s.add_style b: true
        workbook.add_worksheet(:name => "Reporte") do |sheet|
        sheet.add_row ["Municipalidad","#{@mun.name}"], style: heading
        sheet.add_row ["Fecha del reporte","#{Time.now}"], style: heading
        sheet.add_row ["Usuario","#{@user.login_name} #{@user.login_last_name}"], style: heading
        sheet.add_row [""]
        sheet.add_row ["ESTADO ACTUAL DE LOS PROYECTOS"], style: heading
        sheet.add_row ["Proyectos abiertos","#{@boards.count}"]
        sheet.add_row [""]


        

        sheet.add_row ["Proyectos por zona de intervención"], style: heading
        sheet.add_row ["NO ASIGNADA","#{@boards.and(@boards.where(closed: "false").selector,@boards.where(:zone_ids => nil).selector).count}"]
        @mun.zones.sort{|a,b| a.name.delete("^0-9").to_i <=> b.name.delete("^0-9").to_i}.each do |zone|
          sheet.add_row ["#{zone.name}","#{zone.boards.where(closed: "false").count}"]
        end  
        sheet.add_row [""]



        sheet.add_row ["Proyectos por sector de inversión"], style: heading
        sheet.add_row ["NO ASIGNADO","#{@boards.and(@boards.where(tipo: nil).selector,@boards.where(closed: "false").selector).count}"]
        @mun.tipos.each do |tipo|
          sheet.add_row ["#{tipo.name}","#{@boards.where(tipo: tipo).count}"]
        end
        sheet.add_row [""]

        sheet.add_row ["Proyectos por zona de intervención y fondo"], style: heading
        nombres=Array.new()
        nombres<<"Zonas de intervención"
        nombres=nombres+@mun.zones.sort{|a,b| a.name.delete("^0-9").to_i <=> b.name.delete("^0-9").to_i}.map{|z| z.name}
        sheet.add_row nombres.to_a

        auxZonas=Array.new(@mun.zones.count)
        @mun.fondos.each do |fondo|
          i=1
          if(fondo.etapa=="diseno")
            a=sheet.add_row ["#{fondo.name} (Diseño)"]+auxZonas
          elsif(fondo.etapa=="ejecucion")
            a=sheet.add_row ["#{fondo.name} (Ejecución)"]+auxZonas
          elsif(fondo.etapa=="adquisicion")
            a=sheet.add_row ["#{fondo.name} (Adquisición)"]+auxZonas
          elsif(fondo.etapa=="estudios")
            a=sheet.add_row ["#{fondo.name} (Estudios)"]+auxZonas
          elsif(fondo.etapa=="otros")
            a=sheet.add_row ["#{fondo.name} (Otros)"]+auxZonas
          end
          @mun.zones.sort{|a,b| a.name.delete("^0-9").to_i <=> b.name.delete("^0-9").to_i}.each do |zone|
            valuex=zone.boards.and(zone.boards.where(fondo: fondo).selector,zone.boards.where(closed: "false").selector).count
            sheet.rows[a.index].cells[i].value=valuex
            i=i+1
          end
          
        end
        sheet.add_row [""]


        sheet.add_row ["Proyectos por nivel de prioridad"], style: heading
        sheet.add_row ["Proyectos urgentes","#{@count[0]}"]
        sheet.add_row ["Proyectos priorizados","#{@count[1]}"]
        sheet.add_row ["Proyectos no priorizados","#{@count[2]}"]
        sheet.add_row [""]


        sheet.add_row ["Proyectos por etapa"], style: heading
        sheet.add_row ["En creación municipal","#{@total1}"]
        sheet.add_row ["Ingresado","#{@total2}"]
        sheet.add_row ["Observado","#{@total3}"]
        sheet.add_row ["Con aprobación técnica","#{@total4}"]
        sheet.add_row ["Con recursos aprobados","#{@total5}"]
        sheet.add_row ["Preparación licitación","#{@total6}"]
        sheet.add_row ["Evaluación y adjudicación de propuestas","#{@total7}"]
        sheet.add_row ["En ejecución","#{@total8}"]
        sheet.add_row ["Estapa no asignada","#{@total9}"]
        sheet.add_row [""]


        sheet.add_row [""]
        sheet.add_row ["INDICADORES HISTÓRICOS"], style: heading
        sheet.add_row [""]
        dates=Array.new()
        dates<<""
        thisYear=Time.now.year
        firstYear=@mun.created_at.to_date.year
        for i in thisYear.downto(firstYear)
          puts i
          dates<<i.to_s
        end
        puts dates
        sheet.add_row dates.to_a, style: heading


        creacion=Array.new()
        creacion<<"N° de proyectos que pasaron por la etapa 'En creación municipal'"
        ingresado=Array.new()
        ingresado<<"N° de proyectos que pasaron por la etapa 'Ingresado'"
        observado=Array.new()
        observado<<"N° de proyectos que pasaron por la etapa 'Observado'"
        aprobacion=Array.new()
        aprobacion<<"N° de proyectos que pasaron por la etapa 'Con aprobación técnica'"
        recursos=Array.new()
        recursos<<"N° de proyectos que pasaron por la etapa 'Con recursos aprobados'"
        licitacion=Array.new()
        licitacion<<"N° de proyectos que pasaron por la etapa 'Preparación de licitación'"
        evaluacion=Array.new()
        evaluacion<<"N° de proyectos que pasaron por la etapa 'Evaluación y adjudicación de propuestas'"
        ejecucion=Array.new()
        ejecucion<<"N° de proyectos que pasaron por la etapa 'En ejecución'"
        finalizado=Array.new()
        finalizado<<"N° de proyectos que pasaron por la etapa 'Finalizado'"
        for i in thisYear.downto(firstYear)
          creacion[thisYear-i+1]=0
          ingresado[thisYear-i+1]=0
          observado[thisYear-i+1]=0
          aprobacion[thisYear-i+1]=0
          recursos[thisYear-i+1]=0
          licitacion[thisYear-i+1]=0
          evaluacion[thisYear-i+1]=0
          ejecucion[thisYear-i+1]=0
          finalizado[thisYear-i+1]=0
          @mun.boards.each do |b|
            if(b.current_state!="Descartado")
              if(b.state_change_dates[0]!=nil)
                if(b.state_change_dates[0].to_date.year==i)
                  creacion[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[1]!=nil)
                if(b.state_change_dates[1].to_date.year==i)
                  ingresado[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[2]!=nil)
                if(b.state_change_dates[2].to_date.year==i)
                  observado[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[3]!=nil)
                if(b.state_change_dates[3].to_date.year==i)
                  aprobacion[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[4]!=nil)
                if(b.state_change_dates[4].to_date.year==i)
                  recursos[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[5]!=nil)
                if(b.state_change_dates[5].to_date.year==i)
                  licitacion[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[6]!=nil)
                if(b.state_change_dates[6].to_date.year==i)
                  evaluacion[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[7]!=nil)
                if(b.state_change_dates[7].to_date.year==i)
                  ejecucion[thisYear-i+1]+=1
                end
              end
              if(b.state_change_dates[8]!=nil)
                if(b.state_change_dates[8].to_date.year==i)
                  finalizado[thisYear-i+1]+=1
                end
              end
            end
          end
        end
        sheet.add_row creacion.to_a
        sheet.add_row ingresado.to_a
        sheet.add_row observado.to_a
        sheet.add_row aprobacion.to_a
        sheet.add_row recursos.to_a
        sheet.add_row licitacion.to_a
        sheet.add_row evaluacion.to_a
        sheet.add_row ejecucion.to_a
        sheet.add_row finalizado.to_a

        sheet.add_row [""]
        sheet.add_row dates.to_a, style: heading
        plata=Array.new()
        plata<<"Suma de los montos de los proyectos que pasaron por la etapa 'En ejecución'"
        for i in thisYear.downto(firstYear)
          plata[thisYear-i+1]=0
          @mun.boards.each do |b|
            if(b.current_state!="Descartado")
              if(b.state_change_dates[7]!=nil)
                if(b.state_change_dates[7].to_date.year==i)
                  if(b.monto!=nil)
                    plata[thisYear-i+1]+=b.monto.gsub('.','').to_i
                  end
                end
              end
            end
          end
        end
        sheet.add_row plata.to_a
        # sheet.add_row ["","2016","2015","2014"], style: heading
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'En creación municipal'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Ingresado'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Observado'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Con aprobación técnica'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Con recursos aprobados'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Preparación licitación'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Evaluación y adjudicación de propuestas'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'En ejecución'","1000000","2000000","3000000"]
        # sheet.add_row ["Suma de los montos de los proyectos que pasaron por la etapa 'Finalizado'","1000000","2000000","3000000"]
      end
      
      a=Time.now
      p.serialize("tmp/rap-#{a}.xls")
      respond_to do |format|
        format.xls do
           File.read("tmp/rap-#{a}.xls") 
        end
      end
      
      #send_data p.to_stream.read, type: "application/xlsx", filename: "filename.xlsx"
      

    end
      
      
  end

  get '/dashboard', :auth => :connected do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => @user.member_token
    )
    Trello.configure do |config|
      config.developer_public_key = ENV['PUBLIC_KEY']
      config.member_token =  @user.member_token
    end
  

      @mun=Municipio.find_by(id: params[:mun_id])
      @mun_id=@mun.id
      @boards=@mun.boards.and(
        @mun.boards.where(closed:"false").selector,
        @mun.boards.where(:current_state.ne => @mun.states.all[8].name).selector,
        @mun.boards.where(:current_state.ne => @mun.states.all[9].name).selector
        )
      @title="Indicadores de Gestión"
      @valores=Array.new()
      @sizes=Array.new()
      @fondos=Array.new()
      @zones=Array.new()
      @count=Array.new()
      count=0
      @mun.organizations.each do |org|
        if(org.name=="1. Urgentes")
          @count[0]=@boards.where(organization: org).count
        elsif(org.name=="2. Priorizados")
          @count[1]=@boards.where(organization: org).count
        elsif(org.name=="3. No Priorizados")
          @count[2]=@boards.where(organization: org).count
        end
      end
      i=0
      @mun.zones.sort{|a,b| a.name.delete("^0-9").to_i <=> b.name.delete("^0-9").to_i}.each do |zone|
        @mun.fondos.each do |fondo|
          @valores[i]=0
          @sizes[i]=0

          value=zone.boards.and(zone.boards.where(fondo: fondo).selector,zone.boards.where(closed: "false").selector).count
          if(value!=0)
            @valores[i]=value
            @sizes[i]=@valores[i]*10
            
            # @boardsx=@boards.where(fondo: fondo)
            # @boardsx.each do |board|
            #   if(board.fondo!=nil)
            #     if(board.zones.include?(zone))
            #       @valores[i]+=1
            #       @sizes[i]+=10
            #     end
            #   end
            # end
            @zones<<zone.name
            if(fondo.etapa=="diseno")
              @fondos<<fondo.name+" (Diseño)"
            elsif(fondo.etapa=="ejecucion")
              @fondos<<fondo.name+" (Ejecución)"
            elsif(fondo.etapa=="adquisicion")
              @fondos<<fondo.name+" (Adquisición)"
            elsif(fondo.etapa=="estudios")
              @fondos<<fondo.name+" (Estudios)"
            elsif(fondo.etapa=="otros")
              @fondos<<fondo.name+" (Otros)"
            end
            i=i+1
          end
        end
        
      end
      @big_total=0

      @total1 = @boards.where(current_state: /.*#{@mun.states[0].name}.*/).count
      @total2 = @boards.where(current_state: /.*#{@mun.states[1].name}.*/).count
      @total3 = @boards.where(current_state: /.*#{@mun.states[2].name}.*/).count
      puts @total1.to_s+" "+@total2.to_s+" "+@total3.to_s
      @stotal1 = @total1+@total2+@total3
      puts @stotal1
      @big_total=@big_total+@stotal1
      puts @big_total
      @total4 = @boards.where(current_state: /.*#{@mun.states[3].name}.*/).count
      @total5 = @boards.where(current_state: /.*#{@mun.states[4].name}.*/).count
      @stotal2 = @total4+@total5
      @big_total=@big_total+@stotal2
      @total6 = @boards.where(current_state: /.*#{@mun.states[5].name}.*/).count
      @total7 = @boards.where(current_state: /.*#{@mun.states[6].name}.*/).count
      @stotal3 = @total6+@total7
      @big_total=@big_total+@stotal3
      @total8 = @boards.where(current_state: /.*#{@mun.states[7].name}.*/).count
      @big_total=@big_total+@total8
      @total9 = @boards.where(current_state: nil).count+@boards.where(current_state: "").count
      @big_total=@big_total+@total9
      puts @big_total
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
      @title="Calendario"

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
      if(@user.role=="admin"||@user.role=="secpla")
        @title="Gestión de Proyectos"
      else
        @title="Proyectos"
      end
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
        board_settings.created_by=@user.id
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
        board_settings.created_by=@user.id
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
                redirect '/boards'
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
      @title="Archivo de Proyectos"
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
          @municipio=Municipio.find_by(id: params[:mun_id])
          if(@board.current_state==@municipio.states.all[9].name)
            index=@board.state_change_dates.compact.size
            if(index>1)
              puts index
              puts "indiceeeee"
              @last_state=@municipio.states.all[(index-2)].name
            else
              @last_state=""
            end
          elsif(@board.current_state==@municipio.states.all[8].name)
            @last_state=@municipio.states.all[8].name
          end       
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
    @board=Board.find_by(board_id: board_id)
    @municipio=@board.municipio
    @title = "Archivo de Proyectos"
    @last_activity = JSON.parse(client.get("/boards/#{board_id}/actions?limit=1"))[0]["date"].to_date
    haml :board_details
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
