#!/usr/bin/env python
#
# Example: $0 <env_id> <plugin_version> (action)
# Create the user
# Example: ./configdb_user.py 5 1.0.0
# Check the existing user
# Example: ./configdb_user.py 5 1.0.0 check
# Remove the user
# Example: ./configdb_user.py 5 1.0.0 remove

from cluster_data import ClusterData
from keystoneauth1.identity import v2
from keystoneauth1 import session
from keystoneauth1.exceptions import NotFound
from keystoneclient.v2_0 import client
import sys


class KeystoneUser(object):
    """
    Uses the Keystone python client to create the ConfigDB
    user and add it to the admin group.
    """

    def __init__(self):
        pass

    _cluster         = None
    _keystone        = None
    _keystone_user   = None
    _keystone_tenant = None
    _admin_role      = None

    AUTH_ENDPOINT    = 'http://127.0.0.1:35357/v2.0'
    RESET_PASSWORD   = False
    ROLE             = 'admin'

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
    def action(self):
        """
        The custom action passed from the command line
        :rtype: str, None
        """
        if len(sys.argv) >= 4:
            return sys.argv[3]
        else:
            return None

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
    def keystone_user_list(self):
        """
        Query the list of Users
        :rtype: list
        """
        return self.keystone.users.list()

    @property
    def keystone_user(self):
        """
        Get the Keystone user object for the ConfigDB user
        Returns None is there is no such user.
        """
        if self._keystone_user:
            return self._keystone_user
        try:
            self._keystone_user = self.keystone.users.find(name=self.cluster.cdb_user)
        except NotFound:
            self._keystone_user = None
        return self._keystone_user

    @property
    def keystone_tenant(self):
        """
        Get the Keystone tenant object for the ConfigDB tenant.
        """
        if self._keystone_tenant:
            return self._keystone_tenant
        self._keystone_tenant = self.keystone.tenants.find(name=self.cluster.cdb_tenant)
        if not self._keystone_tenant:
            raise RuntimeError('Could not find the tenant: %s!' % self.cluster.cdb_tenant)
        return self._keystone_tenant

    @property
    def keystone_user_parameters(self):
        """
        The parameters of the Keystone user used to
        create the new instance or update the existing one.
        :rtype: dict
        """
        parameters = {
            'name': self.cluster.cdb_user,
            'password': self.cluster.cdb_pass,
            'email': '%s@localhost' % self.cluster.cdb_user,
            'tenant_id': self.keystone_tenant.id,
            'enabled': True,
        }
        return parameters

    def keystone_user_create(self):
        """
        Create the new Keystone ConfigDB user using the parameters
        """
        self.keystone.users.create(**self.keystone_user_parameters)

    def keystone_user_delete(self):
        """
        Delete an existing Keystone ConfigDB user
        """
        if self.keystone_user:
            self.keystone.users.delete(self.keystone_user)

    def keystone_user_update(self):
        """
        Update an existing Keystone ConfigDB user
        """
        parameters = self.keystone_user_parameters
        if not self.RESET_PASSWORD:
            parameters.pop('password', None)
        if self.keystone_user:
            self.keystone.users.update(self.keystone_user, **parameters)

    @property
    def keystone_admin_role(self):
        """
        The Keystone object of the cluster admin role
        """
        if self._admin_role:
            return self._admin_role
        for role in self.keystone.roles.list():
            if role.name == self.ROLE:
                self._admin_role = role
                break
        if not self._admin_role:
            raise RuntimeError('Could not find the role: %s!' % self.ROLE)
        return self._admin_role

    def keystone_user_has_role(self):
        """
        Check if the ConfigDB user has the admin role
        :rtype: bool
        """
        if self.keystone_user and self.keystone_admin_role:
            roles = self.keystone.roles.roles_for_user(
                user=self.keystone_user,
                tenant=self.keystone_tenant,
            )
            for role in roles:
                if role.name == self.ROLE:
                    return True
            return False
        else:
            raise RuntimeError('Both user and role should be present!')

    def keystone_set_role(self):
        """
        Assign the admin role to the ConfigDB user
        """
        if self.keystone_user and self.keystone_admin_role:
            self.keystone.roles.add_user_role(
                user=self.keystone_user,
                role=self.keystone_admin_role,
                tenant=self.keystone_tenant,
            )
        else:
            raise RuntimeError('Both user and role should be present!')

    def run(self):
        """
        Create the ConfigDB user if it doesn't exist or update the existing one.
        The password will not be updated unless RESET_PASSWORD set.
        Assign the admin role if it have not been assigned.
        """
        if self.action == 'remove':
            print('Remove user: %s' % self.cluster.cdb_user)
            self.keystone_user_delete()
            sys.exit(0)
        elif self.action == 'check':
            if self.keystone_user:
                print(self.keystone_user)
            else:
                print('User not found: %s' % self.cluster.cdb_user)
            sys.exit(0)
        else:
            if not self.keystone_user:
                print('User %s not found. Creating...' % self.cluster.cdb_user)
                self.keystone_user_create()
            else:
                print('User %s found. Updating...' % self.cluster.cdb_user)
                self.keystone_user_update()

        if not self.keystone_user_has_role():
            print('User %s assign to role: %s...' % (self.cluster.cdb_user, self.ROLE))
            self.keystone_set_role()

##############################################################################

if __name__ == '__main__':
    config_db_user = KeystoneUser()
    config_db_user.run()
