require 'mongoid'
require 'socket'

class Board
  include Mongoid::Document

  has_and_belongs_to_many :users
  has_and_belongs_to_many :zones

  field :board_id, type: String
  field :starting_list, type: String
  field :ending_list, type: String
  field :monto, type: String
  field :fondo, type: String
  field :coords, type: String
  field :name, type: String
  field :desc, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :closed, type: String
  field :current_state, type: String
  field :state_change_dates, type: Array
  field :archivado, type: String
  field :created_by, type: String
  


  belongs_to :organization
  belongs_to :municipio
  belongs_to :fondo
  belongs_to :tipo
  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["uno","dos","tres"]
      all.each do |product|
        csv << product.pluck(:name,:closed,:end_date)
      end
    end
  end

  def add_members(client,host)
    begin
      board=self
      data=JSON.parse(client.get("/boards/#{board.board_id}/members?filter=admins"))
      admin_ids=Array.new()
      data.each do |admin|
        admin_ids<<admin["id"]
      end
      data=JSON.parse(client.get("/boards/#{board.board_id}/members?filter=normal"))
      normal_ids=Array.new()
      data.each do |normal|
        normal_ids<<normal["id"]
      end
      self.municipio.users.each do |user|
        begin
          data=JSON.parse(client.get("/members/#{user.login_mail}"))
          user.trello_id=data["id"]
          user.save 
          board.users<<user
        rescue
        end
        if(user.trello_id!=nil)
          if(user.role=="admin" || user.role=="secpla")
            if(!admin_ids.include?(user.trello_id))
              begin
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))                 
              rescue => error
                puts error
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                # data=JSON.parse(client.put("/webhooks?idModel=#{user.trello_id}&callbackURL=http://#{host}/virtual_member?data=#{user.trello_id}|#{self.board_id}|#{client.member_token}|#{client.developer_public_key}&description=Callback cuando el miembro deje de ser virtual"))
                # puts "webhook agregado"
                # puts data
              end
            end
          elsif(user.role=="funcionario")
            if(!normal_ids.include?(user.trello_id))
              begin
                JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal")) 
              rescue => error
                puts error
              end
            end
          end
        else
          if(user.role!="alcalde" && user.role!="concejal")
            data=JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
            if(user.role=="admin" || user.role=="secpla")
              if(!admin_ids.include?(user.trello_id))
                begin
                  JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin")) 
                rescue => error
                  puts error
                  JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                  # data=JSON.parse(client.put("/webhooks?idModel=#{user.trello_id}&callbackURL=http://#{host}/virtual_member?data=#{user.trello_id}|#{self.board_id}|#{client.member_token}|#{client.developer_public_key}&description=Callback cuando el miembro deje de ser virtual"))
                  # puts "webhook agregado"
                  # puts data
                end
              end
            else
              if(!normal_ids.include?(user.trello_id))
                begin
                  JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=normal"))
                rescue => error
                  puts error
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
            JSON.parse(client.put("/boards/#{board.board_id}/members?email=#{user.login_mail}&fullName=#{user.login_name} #{user.login_last_name}&type=admin"))
            board.users<<user
            board.save
          end
        rescue => error
          puts error
        end
      end
    rescue => error
      puts error
    end
    
  end

  
end