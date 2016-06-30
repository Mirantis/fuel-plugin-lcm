#!/usr/bin/ruby

require 'net/http'
require 'yaml'
require 'json'
require 'optparse'

ROOT = '/etc/hiera/'.freeze
COMPONENT_NAME = 'fuel9.0'.freeze

ASTUTE_YAML = '/etc/astute.yaml'.freeze

RESOURCES = [
  { 'name' => 'override/node'                   },
  { 'name' => 'override/class'                  },
  { 'name' => 'override/module'                 },
  { 'name' => 'override/plugins'                },
  { 'name' => 'override/common'                 },
  { 'name' => 'override/configuration'          },
  { 'name' => 'override/configuration/role'     },
  { 'name' => 'override/configuration/cluster'  },
  { 'name' => 'class'                           },
  { 'name' => 'module'                          },
  { 'name' => 'nodes'                           },
  { 'name' => 'globals'                         },
  { 'name' => 'deleted_nodes'                   },
  { 'name' => 'astute'                          },
  { 'name' => 'plugins'                         },
  { 'name' => 'override'                        },
].freeze

class Error404 < StandardError; end
class BadAnswer < StandardError; end

options = {}
$verbose = false
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [--upload] [--download]"

  opts.on("--upload", "-u", "upload facts") do |v|
    options[:upload] = true
  end
  opts.on("--download", "-d", "download facts") do |v|
    options[:download] = true
  end

  opts.on("--verbose", "-v", "verbose output") do |v|
    $verbose = true
  end
end.parse!

def handle_request(req, url, retries = 0)
  begin

    use_ssl = url.scheme == 'https'
    r = Net::HTTP.start(url.hostname, url.port, ':use_ssl' => use_ssl) do |http|
      http.request(req)
    end

    return r if r.code == '308' && retries == 0

    raise Error404 if r.code == '404'

    if r.code != '200' && r.code != '201' && r.code != '204'
      puts "Received error response #{r.code} from http server at #{url}: #{r.message}"
      raise BadAnswer
    end

  rescue Errno::ECONNREFUSED => detail
    raise "Failed to connect to http server at #{url}: #{detail}"
  rescue SocketError => detail
    raise "Failed to connect to http server at #{url}: #{detail}"
  end

  r
end

def keystone_v2_authenticate(auth_url,
                             username,
                             password,
                             tenant_name)

  post_args = {
    'auth' => {
      'passwordCredentials' => {
        'username' => username,
        'password' => password
      },
      'tenantName' => tenant_name
    }
  }

  url = URI.parse("#{auth_url}/v2.0/tokens")
  req = Net::HTTP::Post.new url.to_s
  req['content-type'] = 'application/json'
  req.body = post_args.to_json

  res = handle_request(req, url)
  data = JSON.parse res.body
  [data['access']['token']['id'], data]
end

def configdb_create_env(env_id)
  url = URI.parse("#{NAILGUN_ENDPOINT}/api/v1/config/environments")
  req = Net::HTTP::Post.new(url.request_uri, initheader = NAILGUN_HEADERS)

  req.body = JSON.dump(
    {
      'id'               => env_id,
      'components'       => [COMPONENT_NAME],
      'hierarchy_levels' => ['nodes']
    })

  handle_request(req, url)
end

def configdb_env_exists?(env_id)
  raise ArgumentError unless env_id

  url = URI.parse("#{NAILGUN_ENDPOINT}/api/v1/config/environments/#{$env_id}")

  req = Net::HTTP::Get.new(url.request_uri, initheader = NAILGUN_HEADERS)

  begin
      handle_request(req, url)
      return true
    rescue
      return false
  end
end

def upload_namespace(node_id, namespace, data)
  url = URI.parse("#{NAILGUN_ENDPOINT}/api/v1/config/environments/#{$env_id}/nodes/#{node_id}/resources/#{namespace}/values")

  puts "Upload namespace " + url.to_s if $verbose

  req = Net::HTTP::Put.new(url.request_uri, initheader = NAILGUN_HEADERS)
  req.body = JSON.dump data
  r = handle_request(req, url)

  # XXX refact
  if r.code == '308'
    raise RuntimeError unless r['location']
    url = URI.parse(r['location'])

    req = Net::HTTP::Put.new(url.request_uri, initheader = NAILGUN_HEADERS)
    req.body = JSON.dump data
    handle_request(req, url, 1)
  end
end

def download_namespace(node_id, namespace)
  url = URI.parse("#{NAILGUN_ENDPOINT}/api/v1/config/environments/#{$env_id}/nodes/#{node_id}/resources/#{namespace}/values?effective")

  puts "Download namespace " + url.to_s if $verbose

  req = Net::HTTP::Get.new(url.request_uri, initheader = NAILGUN_HEADERS)
  r = handle_request(req, url)

  if r.code == '308'
    raise RuntimeError unless r['location']
    url = URI.parse(r['location'])

    req = Net::HTTP::Get.new(url.request_uri, initheader = NAILGUN_HEADERS)
    r = handle_request(req, url, 1)
  end

  r.body
end

def upload_node_facts(node_id)
  resources = {}
  Dir.glob(ROOT + '**/*').each do |file|
    next unless File.file?(file)

    resource_name = file.gsub(/^#{Regexp.escape(ROOT)}|\.yaml$/,'')

    if File.dirname(resource_name) != '.'
      resource_dir = File.dirname(resource_name)
      resource_name = File.basename(resource_name)

      resources[resource_dir] = {} unless resources.key?(resource_dir)

      resources[resource_dir][resource_name] = YAML.load(File.read(file))
    else
      resources[resource_name] = YAML.load(File.read(file))
    end
  end

  r = configdb_env_exists?($env_id)

  if (r == false)
    begin
      configdb_create_env($env_id)
    rescue BadAnswer
      raise BadAnswer unless configdb_env_exists?($env_id)
	end
  end


  resources.each do |resource, data|
    begin
      upload_namespace node_id, resource, data
    rescue Error404
      puts "#{resource} - 404"
    end
  end
end

def download_node_facts(node_id)
  Dir.glob(ROOT + '**/*').each do |file|
    next unless File.file?(file)
    resource_name = file.gsub(/^#{Regexp.escape(ROOT)}|\.yaml$/,'')

    if File.dirname(resource_name) != '.'
      resource_dir = File.dirname(resource_name)
      resource_name = File.basename(resource_name)

      r = JSON.load(download_namespace(node_id, resource_dir))

      File.open(file, "w") { |f|
        f.write(YAML.dump(r[resource_name]))
      }

    else
      r = JSON.load(download_namespace(node_id, resource_name))
      File.open(file, "w") { |f|
        f.write(YAML.dump(r))
      }

    end
  end
end

def nailgun_env_exists?(env_id)
  raise ArgumentError if env_id.nil? || env_id <= 0

  url = URI.parse("#{NAILGUN_ENDPOINT}/api/clusters")

  req = Net::HTTP::Get.new(url.request_uri, initheader = NAILGUN_HEADERS)

  res = handle_request(req, url)
  JSON.load(res.body).any? { |env| env['id'] == env_id }
end

def env_data
  astute = YAML.load_file(ASTUTE_YAML)
  {
    :user     => astute['fuel-plugin-lcm']['configdb_user'],
    :pass     => astute['fuel-plugin-lcm']['configdb_pass'],
    :tenant   => astute['fuel-plugin-lcm']['metadata']['configdb']['tenant'],
    :fuel_ip  => astute['master_ip'],
    :id       => astute['deployment_id'],
    :node_id  => astute['uid']
  }
end

def component_exists?(component_name)
  url = URI.parse("#{NAILGUN_ENDPOINT}/api/v1/config/components")
  req = Net::HTTP::Get.new(url.request_uri, initheader = NAILGUN_HEADERS)
  JSON.load(handle_request(req, url).body).select { |component| component['name'] == component_name }[0]['id']
end

def component_upload(component_name, resources)
  url = URI.parse("#{NAILGUN_ENDPOINT}/api/v1/config/components")
  req = Net::HTTP::Post.new(url.request_uri, initheader = NAILGUN_HEADERS)
  req.body = JSON.dump(
      'name'                 => component_name,
      'resource_definitions' => resources
  )
  puts req.body
  JSON.load(handle_request(req, url).body)['id']
end

env = env_data
KEYSTONE_ENDPOINT = "http://#{env[:fuel_ip]}:35357".freeze
NAILGUN_ENDPOINT = "http://#{env[:fuel_ip]}:8000".freeze

authtoken = keystone_v2_authenticate(KEYSTONE_ENDPOINT, env[:user], env[:pass],
                                     env[:tenant])[0]

NAILGUN_HEADERS = {
  'Content-type' => 'application/json',
  'X-Auth-Token' => authtoken
}.freeze

raise "Env #{env[:id]} not exists" unless nailgun_env_exists?(env[:id])

$env_id = env[:id]

begin
  component_exists?(COMPONENT_NAME)
rescue NoMethodError
  begin
    component_upload(COMPONENT_NAME, RESOURCES)
    rescue BadAnswer
      component_exists?(COMPONENT_NAME)
  end
end

if options.size == 0
  options[:upload] = true
  options[:download] = true
end

if options[:upload]
  upload_node_facts(env[:node_id])
end

if options [:download]
  download_node_facts(env[:node_id])
end
