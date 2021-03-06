require 'trello'

require_relative '../utils/connecting/user_connector'

class Ollert

  #Logout
  get '/logout', :auth => :connected do
    session[:user] = nil

    flash[:success] = "Sesión cerrada exitosamente"
    redirect '/home'
  end

  #Connect, called from the view authorize.haml
  put '/trello/connect' do
    client = Trello::Client.new(
      :developer_public_key => ENV['PUBLIC_KEY'],
      :member_token => params[:token]
    )

    result = UserConnector.connect client, params[:token], params[:login_mail]
    if(result[:status]==200)
      puts "200"
      session[:user] = result[:id]
      status result[:status]
      body result[:body]
    else
      puts result
      status result[:status]
      session[:user] = nil
      body result[:body]
      flash[:error] = "Cuenta de Trello no coincide con el email provisto"
      redirect '/home'
    end
  end

end