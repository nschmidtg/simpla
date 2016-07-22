class Ollert
  get '/', :auth => :none do
    if !@user.nil? && !@user.member_token.nil?
      redirect '/boards'
    end
    @municipios=Municipio.all
    haml :landing
  end

  not_found do
    flash[:error] = "The page requested could not be found."
    redirect '/'
  end

  get '/seed', :auth => :none do
    mun1=Municipio.find_or_initialize_by id: "1"
    mun1.name="Municipalidad de Til Til"
    estado1=State.find_or_initialize_by id: "1"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun1
    estado1.save

    estado2=State.find_or_initialize_by id: "2"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun1
    estado2.save
    
    estado3=State.find_or_initialize_by id: "3"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun1
    estado3.save
    
    estado4=State.find_or_initialize_by id: "4"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun1
    estado4.save
    
    estado5=State.find_or_initialize_by id: "5"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun1
    estado5.save
    
    estado6=State.find_or_initialize_by id: "6"
    estado6.name="NO ASIGNADO"
    estado6.order="6"
    estado6.municipio=mun1
    estado6.save
        
    mun1.save

    mun2=Municipio.find_or_initialize_by id: "2"
    mun2.name="Municipalidad de Llay Llay"
    estado1=State.find_or_initialize_by id: "7"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun2
    estado1.save

    estado2=State.find_or_initialize_by id: "8"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun2
    estado2.save
    
    estado3=State.find_or_initialize_by id: "9"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun2
    estado3.save
    
    estado4=State.find_or_initialize_by id: "10"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun2
    estado4.save
    
    estado5=State.find_or_initialize_by id: "11"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun2
    estado5.save
    
    estado6=State.find_or_initialize_by id: "12"
    estado6.name="NO ASIGNADO"
    estado6.order="6"
    estado6.municipio=mun2
    estado6.save
        
    mun2.save
    

    mun3=Municipio.find_or_initialize_by id: "3"
    mun3.name="Municipalidad de Nogales"
    estado1=State.find_or_initialize_by id: "13"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun3
    estado1.save

    estado2=State.find_or_initialize_by id: "14"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun3
    estado2.save
    
    estado3=State.find_or_initialize_by id: "15"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun3
    estado3.save
    
    estado4=State.find_or_initialize_by id: "16"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun3
    estado4.save
    
    estado5=State.find_or_initialize_by id: "17"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun3
    estado5.save
    
    estado6=State.find_or_initialize_by id: "18"
    estado6.name="NO ASIGNADO"
    estado6.order="6"
    estado6.municipio=mun3
    estado6.save
        
    mun3.save
    
    count=0
    State.all.each do |s|
        task1=Task.find_or_initialize_by id: "#{count}"
        task1.name="tarea #{count%6} por defecto de estado #{count}"
        task1.desc="descripcion de tarea por defecto de estado #{count}"
        task1.state=s
        count=count+1
        task1.save
        s.save
    end

    redirect '/'
  end
end
