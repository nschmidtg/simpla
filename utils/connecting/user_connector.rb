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
      if(user.role!="alcalde" && user.role!="concejal")
        unless user.member_token.nil? || user.member_token == member_token
          begin
            client.delete("/tokens/#{user.member_token}")
          rescue
            # do nothing
            # most likely token either expired or was revoked
          end
        end
      
        user.member_token = member_token
        user.trello_id = member["id"]
        user.trello_name = member["username"]
        user.gravatar_hash = member["gravatarHash"]
        user.email = member["email"] || user.email
      else
        user.member_token = User.find_by(role: "admin").member_token
        user.trello_id = User.find_by(role: "admin").trello_id
        user.trello_name = User.find_by(role: "admin").trello_name
        user.gravatar_hash = ""
      end

      # set or update other fields
      
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