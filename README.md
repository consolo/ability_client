Ruby Ability Client
===================

## INSTALL

Add it to your Gemfile:

    gem "ability_client", :git => "git://github.com/consolo/ability_client.git", :required => "ability"

## USAGE

The client can be initialized without SSL info, but it will most likely be necessary in production:

    client = Ability::Client.new("SomeUser", "SomePassword", {
      :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read("cert.pem")),
      :ssl_client_key  => OpenSSL::PKey::RSA.new(File.read("key.pem"), "passphrase, if any"),
      :ssl_ca_file     => "ca_certificate.pem",
    })

The client can also use a PKCS#12 format key:

    certificate = OpenSSL::PKCS12.new(File.read("somekey.p12"), "passphrase, if any")
    client = Ability::Client.new("SomeUser", "SomePassword", {
      :ssl_client_cert => certificate.certificate,
      :ssl_client_key  => certificate.key,
      :ssl_ca_file     => certificate.ca_certs
    })

Most API calls like `eligibility_inquiry` will require a `service_id`. Query for service ids to get one:

    client.services
    => [{ :id => 1, :type => "BatchSubmit", :name => "NGS Medicare Part B Submit Claims (Downstate NY)",
    =>    :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchSubmit/1" },
    =>  { :id => 2, :type => "BatchReceiveList", :name => "NGS Medicare Part B Receive Reports / Remits (Downstate NY)",
    =>    :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchReceiveList/2" },
    ...

To make an eligibility API call:

    service_id = 2
    client.eligibility_inquiry(service_id,
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
      client.services
    rescue Ability::ResponseError => e
      error = e.response.error
      code = error.code
      message = error.message
      details = error.details 
    end

You can also rescue for special error cases, like PasswordExpired:

    begin
      client.eligibility_inquiry(2,
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
