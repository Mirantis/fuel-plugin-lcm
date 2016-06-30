#!/usr/bin/env python
#
# Example: $0 <env_id> <plugin_version>
# Example: ./link_registrator.py 3 1.0.0

from cluster_data import ClusterData
from fuelclient.client import APIClient


class LinkRegistrator(object):
    """
    Register the link to the LCM Dashboard in the plugin settings
    """

    def __init__(self):
        pass

    _cluster = None

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
    def registered_plugin_links(self):
        registered_links = APIClient.get_request(self.cluster.plugin_links_url)
        if not isinstance(registered_links, list):
            raise StandardError('Could not get the list of the plugin links from the url: "%s"!' %
                                self.cluster.plugin_links_url
                                )
        return registered_links

    def delete_dashboard_link(self, link_id):
        """
        Delete a registered link by its ID
        :param link_id: ID of the link
        :type link_id: str, int
        """
        print('Remove the registered link ID: %s using the url: "%s"' %
              (link_id, self.cluster.plugin_links_url)
              )
        APIClient.delete_request(self.cluster.plugin_links_url + '/' + str(link_id))

    def delete_all_dashboard_links(self):
        """
        Loop over all registered plugin links and the links from the cluster settings
        and delete all registered links which match one of the links from the settings.
        """
        for registered_link in self.registered_plugin_links:
            for plugin_link in self.cluster.dashboard_links_list:
                if not registered_link['title'] == plugin_link['title']:
                    continue
                if not registered_link['description'] == plugin_link['description']:
                    continue
                if 'id' in registered_link:
                    self.delete_dashboard_link(registered_link['id'])

    def create_dashboard_link(self, link_title, link_description, link_url):
        """
        Create a new plugin link
        :param link_title:
        :param link_description:
        :param link_url:
        :type link_title: str
        :type link_description: str
        :type link_url: str
        """
        link_data = {
            'title': link_title,
            'description': link_description,
            'url': link_url,
        }
        print('Creating the link: "%s" to "%s" using the url: "%s"' %
              (link_title, link_url, self.cluster.plugin_links_url)
              )
        APIClient.post_request(self.cluster.plugin_links_url, link_data)

    def create_all_dashboard_links(self):
        """
        Create all links defined in the plugin settings
        """
        for plugin_link in self.cluster.dashboard_links_list:
            if 'title' in plugin_link and 'description' in plugin_link:
                self.create_dashboard_link(plugin_link['title'], plugin_link['description'], self.cluster.dashboard_url)

    def run(self):
        """
        First, remove all links similar to the defined in the settings,
        then create new links using the URL to the LCM dashboard.
        """
        self.delete_all_dashboard_links()
        self.create_all_dashboard_links()


##############################################################################

if __name__ == '__main__':
    link_registrator = LinkRegistrator()
    link_registrator.run()
