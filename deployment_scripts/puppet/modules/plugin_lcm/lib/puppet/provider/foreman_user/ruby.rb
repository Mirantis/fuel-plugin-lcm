require 'json'
require 'net/http'
require 'uri'

Puppet::Type.type(:foreman_user).provide(:ruby) do
  desc "Manage users in Foreman"

  ###

  attr_accessor :user_id

  def make_request(url, req_type, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.ca_file = File.expand_path(@resource[:ca_file])
    case req_type
      when 'Get'
        request = Net::HTTP::Get.new(uri.request_uri)
      when 'Delete'
        request = Net::HTTP::Delete.new(uri.request_uri)
      when 'Post'
        request = Net::HTTP::Post.new(
          uri.request_uri,
          initheader = {
            'Content-Type' => 'application/json'
          }
        )
        request.body = data if data != ''
      else
        fail "Unsupported request type: #{req_type}"
    end
    request.basic_auth(@resource[:foreman_user], @resource[:foreman_password])
    response = http.request(request)
    if response.code.to_i >= 400
      fail "HTTP Error : #{response.code}(#{response.message})"
    end
    return response
  end

  def exists?
    response = make_request(@resource[:foreman_base_url] + '/api/users', 'Get', '')
    users = JSON.parse(response.body)
    users['results'].each do |user|
      if @resource[:name] == user['login']
        @user_id = user['id'].to_s
        return true
      end
    end
    false
  end

  def destroy
    make_request(@resource[:foreman_base_url] + '/api/users/' + @user_id, 'Delete', '')
  end

  def create
    hash = {
      'user' => {
        'admin' => @resource[:admin],
        'login' => @resource[:name],
        'firstname' => @resource[:name],
        'lastname' => @resource[:name],
        'password' => @resource[:password],
        'mail' => @resource[:mail],
        'auth_source_name' => @resource[:auth_name],
        'roles' => [{'name' => @resource[:role_name]}]
      }
    }
    response = make_request(@resource[:foreman_base_url] + '/api/users', 'Post', JSON.generate(hash))
  end
end
