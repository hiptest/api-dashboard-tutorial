require 'net/http'
require 'json'

PROJECT_ID = 67155
ACCESS_TOKEN = 'xcxIyyffZDy-UJkfeXPYgg'
CLIENT_ID = 'ikxIDJvmOTTPRSMtRV305Q'
UID = 'areeves@kaonet-fr.net'

PROJECT_URL = "https://hiptest.net/api/projects/#{PROJECT_ID}/test_runs"

# That method will actually fetch the data from Hiptest
# and return an array of hashes containing test runs names and statuses
def request_hiptest_status

  uri = URI(PROJECT_URL)
  result = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new uri
    request['Accept'] = "application/vnd.api+json; version=1"
    request['access-token'] = ACCESS_TOKEN
    request['client'] = CLIENT_ID
    request['uid'] = UID
    http.request request
  end

  if result and result.is_a?(Net::HTTPOK)
    response = JSON.parse(result.body)

    # To return an array containing only names and statusese of test runs
    return response['data'].collect do |test_run|
      {
        'name' => test_run['attributes']['name'], 
        'statuses' => test_run['attributes']['statuses']
      }
    end
  end

  # If something wrong happened then tiles won't be refreshed.
  puts 'An error occurs.'
  puts result

  return nil
  
end

# This method is in charge of returning the most
# valuable status for the given statuses.
#
# It's up to you to define here which status you want your
# dashboard to show depending the statuses of a test run
def get_status_text(statuses)

  return "Failed" if statuses['failed'] > 0
  return "Blocked" if statuses['blocked'] > 0
  return "Skipped" if statuses['skipped'] > 0
  return "Work in progress" if statuses['wip'] > 0 || statuses['undefined'] > 0
  return "Retest" if statuses['retest'] > 0
  return "Passed" if statuses['passed'] > 0

  return "Unknown"

end

# This will simply concatenate the statuses
# into a single string
def get_status_details(statuses)

  return statuses.map { |key, value|
    "#{key}: #{value}" if value > 0
  }.join(' ')

end

# Every 30 seconds the dashboard will fetch statuses from Hiptest
# then refresh the tiles accordingly
SCHEDULER.every '30s' do

  test_runs = request_hiptest_status

  unless test_runs.nil?

    send_event(
      'tr-1', 
      { 
        title: test_runs.first['name'], 
        text: get_status_text(test_runs.first['statuses']),
        moreinfo: get_status_details(test_runs.first['statuses'])
      })

    send_event(
      'tr-2', 
      { 
        title: test_runs.last['name'], 
        text: get_status_text(test_runs.last['statuses']),
        moreinfo: get_status_details(test_runs.last['statuses'])
      })

  end

end