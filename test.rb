require 'net/http'
require 'uri'
require 'json'
require 'yaml'

CONFIG = YAML.load_file("secrets.yml")

class Conoha
  attr_accessor :tenant_id, :tenant_name, :username, :password

  def initialize(tenant_id:,tenant_name:, username:,password:)
    @tenant_id = tenant_id
    @tenant_name = tenant_name
    @username = username
    @password = password
  end

  def get_token
    uri = URI.parse("https://identity.tyo1.conoha.io/v2.0/tokens")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request.body = JSON.dump({
      "auth" => {
        "passwordCredentials" => {
          "username" => @username,
          "password" => @password
        },
        "tenantId" => @tenant_id
      }
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end


    JSON.parse(response.body)["access"]["token"]["id"]
  end

  def server
    @token ||= self.get_token
    uri = URI.parse("https://compute.tyo1.conoha.io/v2/#{tenant_id}/servers")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"
    request["X-Auth-Token"] = @token

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response.body
  end

  def vm_boot(vm_id:)
    @token ||= self.get_token
    uri = URI.parse("https://compute.tyo1.conoha.io/v2/#{@tenant_id}/servers/#{vm_id}/action")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request["X-Auth-Token"] = @token
    request.body = JSON.dump({
      "os-start" => nil
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response.code
  end

  def vm_shutdown(vm_id:)
    @token ||= self.get_token
    uri = URI.parse("https://compute.tyo1.conoha.io/v2/#{@tenant_id}/servers/#{vm_id}/action")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request["X-Auth-Token"] = @token
    request.body = JSON.dump({
      "os-stop" => nil
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response.code
  end
end

p CONFIG
conoha = Conoha.new(
  tenant_id: CONFIG["tenant_id"],
  tenant_name: CONFIG["tenant_name"],
  username: CONFIG["username"],
  password: CONFIG["password"]
)

p conoha.server
#id = JSON.parse(conoha.server)["servers"][0]["id"]
#puts id

#p conoha.vm_boot(vm_id: id)
#p conoha.vm_shutdown(vm_id: id)
