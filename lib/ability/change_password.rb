module Ability
  module ChangePassword
    
    class Request < Ability::Request
      attr_reader :user, :password, :service_id, :new_password, :opts

      def initialize(user, password, service_id, new_password, opts)
        @user = user
        @password = password
        @service_id = service_id
        @new_password = new_password
        @opts = opts
      end

      def resource_name
        "PasswordChange"
      end

      def xml
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct! :xml, :standalone => "yes"
        xml.passwordChangeRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
          xml.medicareMainframe {
            xml.application { 
              xml.facilityState opts[:facility_state]
              xml.lineOfBusiness opts[:line_of_business]
            }
            xml.credential {
              xml.userId user
              xml.password password
            }
            if clerk = opts[:clerk]
              xml.clerkCredential {
                xml.userId clerk[:user]
                xml.password clerk[:password]
              }
            end
          }
          xml.newPassword new_password
        }

      end
       
    end
  end
end
