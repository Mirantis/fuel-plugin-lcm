require 'puppet/parameter/boolean'

Puppet::Type.newtype(:foreman_user) do
  desc "Manage users in Foreman"

  ensurable do

  newvalue(:present) do
    provider.create
  end

  newvalue(:absent) do
    provider.destroy
  end

  aliasvalue(:created, :present)
  aliasvalue(:destroyed, :absent)
  defaultto :present
  end

###

  newparam(:name) do
    desc "The user name"

    isnamevar
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
    end
  end

  newparam(:password) do
    desc "The user password in Foreman"

    validate do |value|
      if !value.is_a?(String) or value.length < 6
        raise ArgumentError, "Passwords must be at least 6 characters"
      end
    end
  end

  newparam(:firstname) do
    desc "The user firstname in Foreman"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
    end
  end

  newparam(:lastname) do
    desc "The user lastname in Foreman"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
    end
  end

  newparam(:mail) do
    desc "The user mail in Foreman"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
    end
  end

  newparam(:auth_name) do
    desc "The authorization in Foreman"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
    end
  end

  newparam(:admin, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc "The user can be administrator in Foreman"
  end

  newparam(:role_name) do
    desc "The user role in Foreman"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Role name must be a String not #{value.class}"
      end
    end
  end

  newparam(:foreman_user) do
    desc "The admin user in Foreman"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
    end
  end

  newparam(:foreman_password) do
    desc "The admin user password in Foreman"

    validate do |value|
      if !value.is_a?(String) or value.length < 6
        raise ArgumentError, "Passwords must be at least 6 characters"
      end
    end
  end

  newparam(:foreman_base_url) do
    desc "The Foreman base URL"
  #TODO add some validation to URL param
  end

  newparam(:ca_file) do
    desc "Full path to a Certificate Authority file"
  #TODO add some validation to the ca filepath
  end

end
