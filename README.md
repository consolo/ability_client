Ability Client
==============

## INSTALL

Add it to your Gemfile:

    gem "ability", :git => "git://github.com/consolo/ability_client.git"

## SETUP

First, create a config file:

    :user: someuser
    :password: somepass
    :pem_key: somekey
    :pkcs12_file: /path/to/ability/pkcs12_file
    :ssl_ca_file: /path/to/ca_cert.pem
    :service_id: 323

The ca_cert_file config is required, but if the file does not exist, the client will create one automatically from the existing PKCS12 file.

Set the location of the config file:

    Ability::Client.configure(:config_file => "/path/to/ability.yml")

## USAGE:

Most API calls like `eligibility_inquiry` will require a `service_id`. Query for service ids to get one:

    Ability::Client.services
    => [{ :id => 1, :type => "BatchSubmit", :name => "NGS Medicare Part B Submit Claims (Downstate NY)",
    =>    :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchSubmit/1" },
    =>  { :id => 2, :type => "BatchReceiveList", :name => "NGS Medicare Part B Receive Reports / Remits (Downstate NY)",
    =>    :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchReceiveList/2" },
    ...

To make an eligibility API call:

    # required if not set in initializer or config file
    service_id = 2

    Ability::Client.eligibility_inquiry(
      :service_id => 2,
      :facility_state => "OH",
      :line_of_business => "PartA",
      :details => [
        :fss0_1751,
        :fss0_1752
      ],
      :beneficiary => {
        :hic => "123456789A",
        :last_name => "Doe",
        :first_name => "John",
        :sex => "M",
        :date_of_birth => Date.parse("1925-05-08")
      }
    )

### Errors

Any API call could result in an error from Ability. If an XML response contains an error, an exception with the same error code as the XML message is generated and raised. All generated exceptions descend from Ability::ResponseError. The original error details are accessible from the exception's response object.

    begin
      Ability::Client.services
    rescue Ability::ResponseError => e
      error = e.response.error
      code = error.code
      message = error.message
      details = error.details 
    end

You can also rescue for special error cases, like PasswordExpired:

    begin
      Ability::Client.eligibility_inquiry(
        :facility_state => "OH",
        :line_of_business => "PartA",
        :details => [
          :fss0_1751,
          :fss0_1752
        ],
        :beneficiary => {
          :hic => "123456789A",
          :last_name => "Doe",
          :first_name => "John",
          :sex => "M",
          :date_of_birth => Date.parse("1925-05-08")
        }
      )
    rescue Ability::PasswordExpired => e
      do_stuff
    end
