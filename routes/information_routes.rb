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
    
    estado6=State.find_or_initialize_by id: "6"
    estado6.name="NO ASIGNADO"
    estado6.order="6"
    estado6.municipio=mun1
    estado6.save
    states<<estado6
        
    mun1.save

    mun2=Municipio.find_or_initialize_by id: "2"
    mun2.name="Municipalidad de Llay Llay"
    estado1=State.find_or_initialize_by id: "7"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun2
    estado1.save
    states<<estado1

    estado2=State.find_or_initialize_by id: "8"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun2
    estado2.save
    states<<estado2

    estado3=State.find_or_initialize_by id: "9"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun2
    estado3.save
    states<<estado3

    estado4=State.find_or_initialize_by id: "10"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun2
    estado4.save
    states<<estado4

    estado5=State.find_or_initialize_by id: "11"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun2
    estado5.save
    states<<estado5

    estado6=State.find_or_initialize_by id: "12"
    estado6.name="NO ASIGNADO"
    estado6.order="6"
    estado6.municipio=mun2
    estado6.save
    states<<estado6   
    mun2.save
    

    mun3=Municipio.find_or_initialize_by id: "3"
    mun3.name="Municipalidad de Nogales"
    estado1=State.find_or_initialize_by id: "13"
    estado1.name="No iniciado"
    estado1.order="1"
    estado1.municipio=mun3
    estado1.save
    states<<estado1

    estado2=State.find_or_initialize_by id: "14"
    estado2.name="Formulación"
    estado2.order="2"
    estado2.municipio=mun3
    estado2.save
    states<<estado2

    estado3=State.find_or_initialize_by id: "15"
    estado3.name="Observado"
    estado3.order="3"
    estado3.municipio=mun3
    estado3.save
    states<<estado3

    estado4=State.find_or_initialize_by id: "16"
    estado4.name="Licitación"
    estado4.order="4"
    estado4.municipio=mun3
    estado4.save
    states<<estado4

    estado5=State.find_or_initialize_by id: "17"
    estado5.name="Ejecución"
    estado5.order="5"
    estado5.municipio=mun3
    estado5.save
    states<<estado5

    estado6=State.find_or_initialize_by id: "18"
    estado6.name="NO ASIGNADO"
    estado6.order="6"
    estado6.municipio=mun3
    estado6.save
    states<<estado6  
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

    redirect '/'
  end
end
