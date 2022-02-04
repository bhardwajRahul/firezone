# frozen_string_literal: true

require 'mixlib/shellout'
require 'uri'
require 'net/http'
require 'json'

def capture
  telemetry_id = File.read("/opt/firezone/sv/phoenix/env/TELEMETRY_ID")
  uri = URI("https://telemetry.firez.one/capture/")
  data = {
    api_key: "phc_ubuPhiqqjMdedpmbWpG2Ak3axqv5eMVhFDNBaXl9UZK",
    event: "firezone-ctl reconfigure",
    properties: {
      distinct_id: telemetry_id
    }
  }

  unless File.exist?("#{base_path}/.disable-telemetry") || ENV["TELEMETRY_ENABLED"] == "false"
    Net::HTTP.post(uri, data.to_json, "Content-Type" => "application/json")
  end
end

add_command_under_category 'reconfigure', 'general', 'Reconfigure the application.', 2 do
  status = run_chef("#{base_path}/embedded/cookbooks/dna.json", '--chef-license=accept')

  capture

  if status.success?
    log "#{display_name} Reconfigured!"
    exit! 0
  else
    exit! 1
  end
end