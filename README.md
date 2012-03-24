Ability Client
==============

## INSTALL

Add it to your Gemfile:

    gem "ability", :git => "git://github.com/consolo/ability_client.git"

## SETUP

Set up SSL and configure the client (possibly in an initializer):

    require 'openssl'

    module AbilitySetup

      def self.run
        pkcs12 = OpenSSL::PKCS12.new(File.read('/path/to/pkcs12.p12'), "somekey")
        ca_file = 'config/ability_ca_cert.pem'

        # Write the CA file if it doesn't exist
        if !File.exist?(ca_file)
          File.open('config/ability_ca_cert.pem', 'w') { |f|
            f.puts pkcs12.ca_certs.collect(&:to_s).join("\n")
          }
        end

        Ability::Client.configure(
          :user => "someuser",
          :password => "somepass",
          :service_id => 3932,
          :ssl_client_cert => pkcs12.certificate,
          :ssl_client_key => pkcs12.key,
          :ssl_ca_file => ca_file
        )
      end
    end

    AbilitySetup.run

## USAGE:

Most API calls like `eligibility_inquiry` will require a `service_id`. Query for service ids to get one:

    Ability::Client.services.first
    => [{ "id" => "1", "type" => "BatchSubmit", "name" => "NGS Medicare Part B Submit Claims (Downstate NY)"

To make an eligibility API call:

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

### Errors

Any API call could result in an error from Ability. If an XML response contains an error, an exception with the same error code as the XML message is generated and raised. All generated exceptions descend from Ability::ResponseError. The original error details are accessible from the exception's `error` object.

    begin
      Ability::Client.services
    rescue Ability::ResponseError => exception
      error = exception.error
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
    rescue Ability::PasswordExpired => exception
      do_stuff
    end
