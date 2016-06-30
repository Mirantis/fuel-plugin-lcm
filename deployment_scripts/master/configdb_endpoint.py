#!/usr/bin/env python
#
# Example: $0 <env_id> <plugin_version>
# Example: ./configdb_endpoint.py 5 1.0.0

from cluster_data import ClusterData
from keystoneauth1.identity import v2
from keystoneauth1 import session
from keystoneclient.v2_0 import client
import sys


class KeystoneEndpoint(object):
    """
    Uses the Keystone python client to create the ConfigDB
    service and correspondent endpoint.
    """

    def __init__(self):
        pass

    _cluster                    = None
    _keystone                   = None
    _keystone_service_desc      = None
    _keystone_service_name      = None
    _keystone_service_type      = None
    _keystone_endpoint_location = None

    AUTH_ENDPOINT = 'http://127.0.0.1:35357/v2.0'

    @property
    def cluster(self):
        """
        The cluster data object
        :rtype: ClusterData
        """
        if self._cluster:
            return self._cluster
        self._cluster = ClusterData()
        return self._cluster

    @property
    def keystone(self):
        """
        The Keystone client object with auth enabled
        :rtype: keystone.client.Client
        """
        if self._keystone:
            return self._keystone
        auth = v2.Password(
            auth_url=self.AUTH_ENDPOINT,
            tenant_name=self.cluster.auth_tenant,
            username=self.cluster.auth_username,
            password=self.cluster.auth_password,
        )
        sess = session.Session(auth=auth)
        self._keystone = client.Client(session=sess)
        return self._keystone

    @property
    def keystone_services_list(self):
        """
        Query the list of Services
        :rtype: list
        """
        return self.keystone.services.list()

    @property
    def keystone_endpoints_list(self):
        """
        Query the list of Endpoints
        :rtype: list
        """
        return self.keystone.endpoints.list()

    def get_service_uid(self, service_name, service_type):
        """
        Check if specified service is installed, enabled
        and has specified service type
        Return its uid
        :rtype: str
        """
        for service in self.keystone_services_list:
            if (service.name == service_name and \
                service.type == service_type and \
                service.enabled == True):
                return str(service.id)
        return ''

    def get_endpoint_uid(self, service_id):
        """
        Check if endpoint for specified
        service uid is created
        Return its uid
        :rtype: str
        """
        for endpoint in self.keystone_endpoints_list:
            if (endpoint.service_id == service_id):
                return str(endpoint.id)
        return ''

    def get_endpoint_params(self, service_id):
        """
        Return params for specified service uid
        :rtype: array
        """
        for endpoint in self.keystone_endpoints_list:
            if (endpoint.service_id == service_id):
                return str(endpoint.region), \
                       str(endpoint.adminurl), \
                       str(endpoint.internalurl), \
                       str(endpoint.publicurl)
        return '', '', '', ''

    def create_service(self, service_name, service_type, service_desc):
        """
        Create keystone service enabled
        with specified service name, type and description
        Return its uid
        :rtype: str
        """
        service = self.keystone.services.create(
            name=service_name, service_type=service_type,
            description=service_desc)
        if service.id == '':
            raise RuntimeError('Service %s was not created' % service_name)
        return service.id

    def create_endpoint(self, region, adminurl, publicurl, internalurl, service_id):
        """
        Create keystone endpoint enabled
        with specified region, adminurl, publicurl, internalurl, service id
        Return its uid
        :rtype: str
        """
        endpoint = self.keystone.endpoints.create(
            region=region, service_id=service_id,
            publicurl=publicurl, adminurl=adminurl,
            internalurl=internalurl)
        return endpoint.id

    @property
    def keystone_service_type(self):
        """
        Get the Keystone service type object for the ConfigDB service.
        """
        if self._keystone_service_type:
            return self._keystone_service_type
        self._keystone_service_type = self.cluster.cdb_service_type
        if not self._keystone_service_type:
            raise RuntimeError('Service type not given!')
        return self._keystone_service_type

    @property
    def keystone_service_name(self):
        """
        Get the Keystone service name object for the ConfigDB service.
        """
        if self._keystone_service_name:
            return self._keystone_service_name
        self._keystone_service_name = self.cluster.cdb_service_name
        if not self._keystone_service_name:
            raise RuntimeError('Service name not given!')
        return self._keystone_service_name

    @property
    def keystone_service_desc(self):
        """
        Get the Keystone service description object for the ConfigDB service.
        """
        if self._keystone_service_desc:
            return self._keystone_service_desc
        self._keystone_service_desc = self.cluster.cdb_service_desc
        if not self._keystone_service_desc:
            raise RuntimeError('Service description not given!')
        return self._keystone_service_desc

    @property
    def keystone_endpoint_location(self):
        """
        Get the Keystone endpoint location object for the ConfigDB service.
        """
        if self._keystone_endpoint_location:
            return self._keystone_endpoint_location
        self._keystone_endpoint_location = self.cluster.cdb_endpoint_location
        if not self._keystone_endpoint_location:
            raise RuntimeError('Keystone endpoint location not given!')
        return self._keystone_endpoint_location

    def run(self):
        """
        Create the ConfigDB service if it doesn't exist.
        Create the ConfigDB endpoint if it doesn't exist.
        """
        service_uid = self.get_service_uid(self.keystone_service_name,
            self.keystone_service_type)
        nailgun_service_uid = self.get_service_uid('nailgun', 'fuel')
        if service_uid == '':
            service_uid = self.create_service(self.keystone_service_name,
                          self.keystone_service_type, self.keystone_service_desc)

        region, adminurl, internalurl, publicurl = self.get_endpoint_params(nailgun_service_uid)
        url = adminurl + self.keystone_endpoint_location
        endpoint_uid = self.get_endpoint_uid(service_uid)
        if endpoint_uid == '':
            endpoint_uid = self.create_endpoint(region, url, url, url, service_uid)
            if endpoint_uid == '':
                raise RuntimeError('Endpoint for service %s was not created' % service_uid)

##############################################################################

if __name__ == '__main__':
    config_db_endpoint = KeystoneEndpoint()
    config_db_endpoint.run()
