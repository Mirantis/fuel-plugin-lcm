require 'net/http'
require 'json'
require 'socket'

class UnexpectedHTTPCodeError < RuntimeError
  attr_reader :uri
  attr_reader :code
  def initialize(uri, code)
    @uri = uri
    @code = code
    super("Got unexpected status code from #{@uri}: #{@code}")
  end
end

class Hiera
  module Backend
    class Nailgun_backend
      def initialize(_cache = nil)
        @cache = {}
        @http = {}
        @node_ids = {}
        @nailgun_config = Config[:nailgun]
        @keystone_config = Config[:keystone]
        @cache_timeout = @nailgun_config['cache_timeout']
        if @cache_timeout.nil?
          @cache_timeout = 120
        end

        Hiera.debug('Hiera nailgun backend starting')

        @keystone_url = @keystone_config['endpoint'] + '/' \
          + @keystone_config['api']

        @authtoken = keystone_v2_authenticate(
          @keystone_url,
          @keystone_config['credentials']['user'],
          @keystone_config['credentials']['pass'],
          @keystone_config['credentials']['tenant'])[0]

        @nailgun_url = @nailgun_config['endpoint'] + '/api/' \
          + @nailgun_config['api']
      end

      def lookup(key, scope, order_override, resolution_type)

        scope['fqdn'] = Socket.gethostname if scope['fqdn'].nil?

        (node_id, cluster_id) = nailgun_node_id(scope['fqdn'])
        Hiera.debug("Nailgun node id #{node_id}, cluster: #{cluster_id}")

        answer = nil
        Backend.datasources(scope, order_override) do |source|
          data = nailgun_api_request(cluster_id, node_id, source)

          next if !data || !data.include?(key)

          new_answer = Backend.parse_answer(data[key], scope)

          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.is_a?(Array) || new_answer.is_a?(String)
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.is_a? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer, answer)
          else
            answer = new_answer
            break
          end
        end
        answer
      end

      private

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

        url = URI.parse("#{auth_url}/tokens").to_s
        req = Net::HTTP::Post.new url
        req['content-type'] = 'application/json'
        req.body = post_args.to_json

        Hiera.debug("Authenticating in Keystone")
        res = request_json(req)
        return [res['access']['token']['id'], res]
      end


      def get_http(host, port, scheme)
        key = [host, port, scheme]
        if !@http.has_key?(key)
          @http[key] = Net::HTTP.new(host, port)
          @http[key].use_ssl = scheme == 'https'
        end
        return @http[key]
      end

      def request_json(url_or_req, depth = 5)
        if depth <= 0
          raise "Too many HTTP redirects or auth failures"
        end
        if url_or_req.is_a?(String)
          uri = URI.parse(url_or_req)
          req = Net::HTTP::Get.new(uri.to_s())
          req['X-Auth-Token'] = @authtoken
        else
          req = url_or_req
          uri = URI.parse(req.path)
        end
        Hiera.debug("Requesting URI #{uri}")
        http = get_http(uri.hostname, uri.port, uri.scheme)
        resp = http.request(req)
        case resp.code
        when '200'
        when '308'
          if !req.is_a?(Net::HTTP::Get)
            raise "Don't know how to redirect request with method #{req.method}"
          end
          new_req = Net::HTTP::Get.new(resp['location'])
          Hiera.debug("Got redirect to #{resp['location']}")
          return request_json(new_req, depth - 1)
        when '401'
          @authtoken = keystone_v2_authenticate(
            @keystone_url,
            @keystone_config['credentials']['user'],
            @keystone_config['credentials']['pass'],
            @keystone_config['credentials']['tenant'])[0]
          req['X-Auth-Token'] = @authtoken
          return request_json(req, depth - 1)
        else
          Hiera.debug("Got unexpected code #{resp.code}: #{resp}")
          raise UnexpectedHTTPCodeError.new(uri, resp.code)
        end
        return JSON.parse(resp.body)
      end

      def nailgun_node_id(fqdn)
        if @node_ids.has_key?(fqdn)
          return @node_ids[fqdn]
        end
        data = request_json(@nailgun_url + '/nodes')
        @node_ids = Hash[data.map do |node| [node['fqdn'], [node['id'], node['cluster']]] end]
        if !@node_ids.has_key?(fqdn)
          raise "No node with fqdn #{fqdn} found"
        end
        return @node_ids[fqdn]
      end

      def cached_request(url)
        now = Time.now().to_i()
        if @cache.has_key?(url) && (@cache[url][:expires_at] >= now)
          Hiera.debug("Getting from cache #{url}")
          return @cache[url][:data]
        end
        begin
          res = request_json(url)
        rescue UnexpectedHTTPCodeError => e
          if e.code != '404'
            raise e
          end
          res = {}
        end
        @cache[url] = {
          :expires_at => now + @cache_timeout,
          :data => res,
        }
        return res
      end

      def nailgun_api_request(cluster_id, node_id, source)
        if File.dirname(source) != '.'
          k = File.basename(source)
          source = File.dirname(source)
        else
          k = nil
        end
        res = cached_request("#{@nailgun_url}/config/environments/#{cluster_id.to_s}/nodes/#{node_id.to_s}/resources/#{source}/values?effective")
        if k.nil?
          return res
        else
          begin
            return res[k]
          rescue
            return nil
          end
        end
      end
    end
  end
end
