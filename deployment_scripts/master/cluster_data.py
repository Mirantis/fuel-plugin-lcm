#!/usr/bin/env python
#
# The library to obtain the cluster information
# using the Fuel client.

from fuelclient.objects import Environment
import sys


class ClusterData(object):
    """
    Uses the Fuel python client libraries to
    extract the cluster settings and get several
    variables from the data structure.
    """

    _client = None
    _data = None
    _network_data = None
    _plugin_data = None

    def __init__(self, cluster_id=None, plugin_version=None):
        """
        :param cluster_id: Manually set the cluster ID instead of taking it from the arguments
        :param plugin_version: Manually set the plugin_version instead of taking it from the arguments
        :type cluster_id: str
        :type plugin_version: str
        """
        self._cluster_id = cluster_id
        self._plugin_version = plugin_version

    @property
    def cluster_id(self):
        """
        The ID of the cluster
        :rtype: str
        """
        if self._cluster_id:
            return self._cluster_id
        if len(sys.argv) < 2:
            raise RuntimeError('You should provide the cluster_id and the plugin_version!')
        return str(sys.argv[1])

    @property
    def plugin_version(self):
        """
        The plugin version. Optional.
        :rtype: str, None
        """
        if self._plugin_version:
            return self._plugin_version
        if len(sys.argv) >= 3:
            return str(sys.argv[2])
        else:
            return None

    @property
    def client(self):
        """
        The instance of the Fuel Client for this cluster
        :rtype: fuelclient.objects.environment.Environment
        """
        if self._client:
            return self._client
        self._client = Environment(self.cluster_id)
        return self._client

    @property
    def data(self):
        """
        The settings data returned by the Fuel client
        :rtype: dict
        """
        if self._data:
            return self._data
        self._data = self.client.get_settings_data()
        if not isinstance(self._data, dict):
            raise RuntimeError('Could not get the cluster settings data!')
        return self._data

    @property
    def network_data(self):
        """
        The network data returned by the Fuel client
        :rtype: dict
        """
        if self._network_data:
            return self._network_data
        self._network_data = self.client.get_network_data()
        if not isinstance(self._network_data, dict):
            raise RuntimeError('Could not get the network settings data!')
        return self._network_data

    @property
    def versions_data(self):
        """
        The "versions" structure inside the settings data.
        It contains a list of LCM plugin data structures for every
        version of the plugin.
        :rtype: list
        """
        versions = self.data.get('editable', {}).get('fuel-plugin-lcm', {}).get('metadata', {}).get('versions', [])
        if not isinstance(versions, list) or len(versions) == 0:
            raise RuntimeError('Could not find the fuel-plugin-lcm versions data block!')
        return versions

    @property
    def plugin_data(self):
        """
        The plugin settings structure for the provided plugin version.
        Or the first one if there is no version provided.
        :rtype: dict
        """
        if self._plugin_data:
            return self._plugin_data
        if not self.plugin_version:
            self._plugin_data = self.versions_data[0]
        else:
            for version in self.versions_data:
                if version.get('metadata', {}).get('plugin_version', None) == self.plugin_version:
                    self._plugin_data = version
                    break
        if not self._plugin_data:
            raise RuntimeError('Could not find any fuel-plugin-lcm data blocks for version: %s!' % self.plugin_version)
        return self._plugin_data

    @property
    def auth_username(self):
        """
        The Nailgun admin user name
        :rtype: str
        """
        username = self.data.get('editable', {}).get('access', {}).get('user', {}).get('value', None)
        if not username:
            raise RuntimeError('Could not get auth username from the cluster data!')
        return username

    @property
    def auth_password(self):
        """
        The Nailgun admin user password
        :rtype: str
        """
        password = self.data.get('editable', {}).get('access', {}).get('password', {}).get('value', None)
        if not password:
            raise RuntimeError('Could not get auth password from the cluster data!')
        return password

    @property
    def auth_tenant(self):
        """
        The Nailgun admin user tenant
        :rtype: str
        """
        tenant = self.data.get('editable', {}).get('access', {}).get('tenant', {}).get('value', None)
        if not tenant:
            raise RuntimeError('Could not get auth tenant from the cluster data!')
        return tenant

    @property
    def cdb_user(self):
        """
        The ConfigDB user name
        :rtype: str
        """
        cdb_user = self.plugin_data.get('configdb_user', {}).get('value', None)
        if not cdb_user:
            raise RuntimeError('Could not get cdb_user from the plugin data!')
        return cdb_user

    @property
    def cdb_pass(self):
        """
        The ConfigDB user password
        :rtype: str
        """
        cdb_pass = self.plugin_data.get('configdb_pass', {}).get('value', None)
        if not cdb_pass:
            raise RuntimeError('Could not get cdb_pass from the plugin data!')
        return cdb_pass

    @property
    def cdb_tenant(self):
        """
        The ConfigDB user tenant
        :rtype: str
        """
        cdb_tenant = self.plugin_data.get('metadata', {}).get('configdb', {}).get('tenant', None)
        if not cdb_tenant:
            raise RuntimeError('Could not get cdb_tenant from the plugin data!')
        return cdb_tenant

    @property
    def cdb_service_name(self):
        """
        ConfigDB service_name
        :rtype: str
        """
        cdb_service_name = self.plugin_data.get('metadata', {}).get('configdb', {}).get('service_name', None)
        if not cdb_service_name:
            raise RuntimeError('Could not get cdb_service_name from the plugin data!')
        return cdb_service_name

    @property
    def cdb_service_type(self):
        """
        ConfigDB service_type
        :rtype: str
        """
        cdb_service_type = self.plugin_data.get('metadata', {}).get('configdb', {}).get('service_type', None)
        if not cdb_service_type:
            raise RuntimeError('Could not get cdb_service_type from the plugin data!')
        return cdb_service_type

    @property
    def cdb_service_desc(self):
        """
        ConfigDB service_description
        :rtype: str
        """
        cdb_service_desc = self.plugin_data.get('metadata', {}).get('configdb', {}).get('service_description', None)
        if not cdb_service_desc:
            raise RuntimeError('Could not get cdb_service_desc from the plugin data!')
        return cdb_service_desc

    @property
    def cdb_endpoint_location(self):
        """
        ConfigDB endpoint_location
        :rtype: str
        """
        cdb_endpoint_location = self.plugin_data.get('metadata', {}).get('configdb', {}).get('endpoint_location', None)
        if not cdb_endpoint_location:
            raise RuntimeError('Could not get cdb_endpoint_location from the plugin data!')
        return cdb_endpoint_location

    @property
    def public_vip_is_enabled(self):
        """
        Check if the Public VIP is enabled in the LCM plugin settings
        :rtype: bool
        """
        return self.plugin_data.get('public_vip_enabled', {}).get('value', False)

    @property
    def lcm_vip(self):
        """
        The management VIP of the LCM plugin
        :return: str
        """
        return self.network_data.get('vips', {}).get('lcm', {}).get('ipaddr', None)

    @property
    def lcm_vip_public(self):
        """
        The management VIP of the LCM plugin
        :return: str
        """
        return self.network_data.get('vips', {}).get('lcmpub', {}).get('ipaddr', None)

    @property
    def active_vip(self):
        """
        Public VIP if it's enabled,
        management VIP otherwise.
        :rtype: str
        """
        if self.public_vip_is_enabled:
            ip = self.lcm_vip_public
        else:
            ip = self.lcm_vip
        if not ip:
            raise StandardError('Could not get the active LCM VIP address! Is LCM plugin enabled for this cluster?')
        return str(ip)

    @property
    def lcm_stats_port(self):
        """
        The HAProxy status port
        :return: int
        """
        return self.plugin_data.get('metadata', {}).get('ports', {}).get('haproxy_stats', None)

    @property
    def haproxy_status_url(self):
        """
        The URL used to access the HAProxy status page
        :return: str
        """
        url = 'http://'
        if not self.lcm_stats_port:
            raise RuntimeError('Could not get the stats port!')
        url += self.active_vip
        url += ':'
        url += str(self.lcm_stats_port)
        url += '/stats;csv'
        return url

    @property
    def plugin_links_url(self):
        """
        The URL used to register the plugin links for this cluster
        :rtype: str
        """
        return 'clusters/' + self.cluster_id + '/plugin_links'

    @property
    def dashboard_url(self):
        """
        The URL of the LCM Plugin Dashboard
        :rtype: str
        """
        return 'https://' + self.active_vip + '/'

    @property
    def dashboard_links_list(self):
        """
        The list of dashboard link of the LCM plugin
        :rtype: list
        """
        links = self.plugin_data.get('metadata', {}).get('dashboard_links', None)
        if not links:
            raise RuntimeError('Could not get the list of the Dashboard links!')
        return links
