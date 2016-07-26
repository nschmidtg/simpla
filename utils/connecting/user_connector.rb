class UserConnector
  def self.connect(client, member_token, current_user = nil)
    member = MemberAnalyzer.analyze(MemberFetcher.fetch(client, member_token))

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
    user.save

    return {
      status: 200,
      body: {username: member["username"], gravatar_hash: member["gravatarHash"]}.to_json,
      id: user.id
    }
  end
end