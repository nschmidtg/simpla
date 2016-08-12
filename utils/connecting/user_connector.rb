class UserConnector
  def self.connect(client, member_token, login_mail, current_user = nil)
    member = MemberAnalyzer.analyze(MemberFetcher.fetch(client, member_token))
    if(member["email"]==login_mail)
      user = nil
      if current_user.nil?
        user = User.find_or_initialize_by login_mail: member["email"]
      else
        unless member["email"] == current_user.login_mail || User.find_by(login_mail: member["email"]).nil?
          return {
            body: "User already exists using that account. Log out to connect with that account.",
            status: 400
          }
        end
        user = current_user
      end

      unless user.member_token.nil? || user.member_token == member_token
        begin
          client.delete("/tokens/#{user.member_token}")
        rescue
          # do nothing
          # most likely token either expired or was revoked
        end
      end

      user.member_token = member_token

      # set or update other fields
      user.trello_id = member["id"]
      user.trello_name = member["username"]
      user.gravatar_hash = member["gravatarHash"]
      user.email = member["email"] || user.email

      
        mun=user.municipio
        if(mun!=nil)
          client = Trello::Client.new(
            :developer_public_key => ENV['PUBLIC_KEY'],
            :member_token => User.find_by(role: "admin").member_token
          )
          mun.organizations.each do |org|
            if(user.role=="admin" || user.role=="secpla")
              if(user.trello_id!=nil)
                JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
              else
                JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
              end
            else
              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
            end
          end
          mun.boards.each do |board|
            if(user.role=="admin" || user.role=="secpla")
              if(user.trello_id!=nil)
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
              else
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
              end
            else
              JSON.parse(client.put("/boards/#{board.borad_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
            end  
          end
          mun.launched="true"
          mun.save
      end
      user.save

      return {
        status: 200,
        body: {username: member["username"], gravatar_hash: member["gravatarHash"]}.to_json,
        id: user.id
      }
    else
      return {
        status: 401
      }
    end
  end
end