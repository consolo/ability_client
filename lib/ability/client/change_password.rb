class Ability::Client::ChangePassword

  CHANGE_PASSWORD_ENDPOINT = "https://access.abilitynetwork.com/portal/seapi/services/PasswordChange"

  def initialize(client, service_id, new_password, opts)
    @client = client
    @service_id = service_id
    @new_password = new_password
    @opts = opts
  end

  def submit
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml, :standalone => "yes"
    xml.passwordChangeRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
      xml.medicareMainframe {
        xml.application { 
          xml.facilityState @opts[:facility_state]
          xml.lineOfBusiness @opts[:line_of_business]
        }
        xml.credential {
          xml.userId @client.user
          xml.password @client.password
        }
        if clerk = @opts[:clerk]
          xml.clerkCredential {
            xml.userId clerk[:user]
            xml.password clerk[:password]
          }
        end
      }
      xml.newPassword @new_password
    }

    doc = @client.parse_xml(@client.post("#{CHANGE_PASSWORD_ENDPOINT}/#{@service_id}", xml.target!))
    
    if doc.elements.to_a("passwordChangeResponse").first
      # Change client password unless clerk password is being changed
      @client.password = @new_password unless @opts[:clerk]
    end
  end
end
