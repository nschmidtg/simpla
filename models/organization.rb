require 'mongoid'

class Organization
  include Mongoid::Document

  field :org_id, type: String
  field :name, type: String

  belongs_to :municipio


  def add_members(client,host,port)
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
	      if(user.trello_id!=nil)
	        if(user.role=="admin" || user.role=="secpla")
	          if(!admin_ids.include?(user.trello_id))
	            begin
	              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
	             	data=JSON.parse(client.get("/members/#{user.login_mail}"))
			          aux=User.find_by(trello_id: data["id"])
			          if(aux==nil)
			            puts "aux nulo"
			            user.trello_id=data["id"]
			            user.save                  
			          end
	             rescue
	              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
	             end
	          end
	        elsif(user.role=="funcionario")
	          if(!normal_ids.include?(user.trello_id))
	            begin
	              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
	            	data=JSON.parse(client.get("/members/#{user.login_mail}"))
			          aux=User.find_by(trello_id: data["id"])
			          if(aux==nil)
			            puts "aux nulo"
			            user.trello_id=data["id"]
			            user.save                  
			          end
	            rescue
	            end
	          end
	        end
	      else
	        if(user.role!="alcalde" && user.role!="concejal")
	          data=JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
	          data=JSON.parse(client.get("/members/#{user.login_mail}"))
	          aux=User.find_by(trello_id: data["id"])
	          if(aux==nil)
	            puts "aux nulo"
	            user.trello_id=data["id"]
	            user.save                  
	          end
	        
	          if(user.role=="admin" || user.role=="secpla")
	            begin
	              JSON.parse(client.put("/organizations/#{org.org_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
	            	data=JSON.parse(client.get("/members/#{user.login_mail}"))
			          aux=User.find_by(trello_id: data["id"])
			          if(aux==nil)
			            puts "aux nulo"
			            user.trello_id=data["id"]
			            user.save                  
			          end
	            rescue => error
	            	puts error
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
	          aux=User.find_by(trello_id: data["id"])
	          if(aux==nil)
	            puts "aux nulo"
	            user.trello_id=data["id"]
	            user.save                  
	          end
	        end
	      rescue
	      end
	    end
	  rescue => error
	  	puts error
	  end
  end
end