require 'mongoid'

class Organization
  include Mongoid::Document

  has_many :boards

  field :org_id, type: String
  field :name, type: String

  belongs_to :municipio


  def add_members(client,host)
  	begin
	  	org=self
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

	    self.municipio.users.each do |user|
	    	begin
		    	data=JSON.parse(client.get("/members/#{user.login_mail}"))
	        user.trello_id=data["id"]
	        user.save 
	      rescue
	      end
	      if(user.trello_id!=nil)
	        if(user.role=="admin" || user.role=="secpla")
	          if(!admin_ids.include?(user.trello_id))
	            begin
	              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin")) 	
	            rescue =>error
	            	puts error
	            	JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
	            	# data=JSON.parse(client.put("/webhooks?idModel=#{self.org_id}&callbackURL=http://#{host}/virtual_member?data=#{self.org_id}|#{self.org_id}|#{client.member_token}|#{client.developer_public_key}&description=Callback cuando el miembro deje de ser virtual"))
              #   puts "webhook agregado"
              #   puts data
	            end
	          end
	        elsif(user.role=="funcionario")
	          if(!normal_ids.include?(user.trello_id))
	            begin
	              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
	            rescue => error
	            	puts error
	            end
	          end
	        end
	      else
	        if(user.role!="alcalde" && user.role!="concejal")
	          data=JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
	          if(user.role=="admin" || user.role=="secpla")
	          	if(!admin_ids.include?(user.trello_id))
		            begin
		              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
		            rescue => error
		            	puts error
		            	JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
		            	# data=JSON.parse(client.put("/webhooks?idModel=#{self.org_id}&callbackURL=http://#{host}/virtual_member?data=#{self.org_id}|#{self.org_id}|#{client.member_token}|#{client.developer_public_key}&description=Callback cuando el miembro deje de ser virtual"))
	              #   puts "webhook agregado"
	              #   puts data
		            end
		          end
	          end
	        end
	      end
	    end
	    users_admins=User.where(:role => "admin")
	    users_admins.each do |user|
	      begin
	        if(!admin_ids.include?(user.trello_id))
	          JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
	       		data=JSON.parse(client.get("/members/#{user.login_mail}"))
            user.trello_id=data["id"]
            user.save 
	        end
	      rescue
	      end
	    end
	  rescue => error
	  	puts error
	  end
  end
end