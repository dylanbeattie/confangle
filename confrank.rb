require 'google/apis/drive_v2'
require 'google/api_client/client_secrets'
require 'json'
require 'sinatra'
require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

enable :sessions
set :session_secret, 'df0978as9d8fy9a8sdfy9asdf9a8sdyf9a8sd98y98yioadsfya978'
set :public_folder, 'public'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Confrank'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "sheets.googleapis.com-ruby-quickstart.yaml")
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

get '/' do
  unless session.has_key?(:credentials)
    redirect to('/oauth2callback')
  end
  client_opts = JSON.parse(session[:credentials])
  auth_client = Signet::OAuth2::Client.new(client_opts)
  sheets = Google::Apis::SheetsV4::SheetsService.new
  spreadsheet_id = '1W900gpmm-qMWf0a9hcM1RuEGKitL_vtd5_Uf-QR_A0E'
  range = '2018 CFP !A1:EG'
  response = sheets.get_spreadsheet_values(spreadsheet_id, range, options: {authorization: auth_client})
  headings_range = '2018 CFP !A1:S1'
  headings_response = sheets.get_spreadsheet_values(spreadsheet_id, headings_range, options: {authorization: auth_client})
  sessions_range = '2018 CFP !A2:S'
  sessions_response = sheets.get_spreadsheet_values(spreadsheet_id, sessions_range, options: {authorization: auth_client})
  haml :talk_per_page, :locals => { headings: headings_response.values[0], sessions: sessions_response.values }
end

get '/config_dump' do
  client_secrets_json = ENV['GOOGLE_CLIENT_SECRETS'] || File.read("client_secrets.json")
  client_secrets_json
end

get '/oauth2callback' do
  client_secrets_json = ENV['GOOGLE_CLIENT_SECRETS'] || File.read("client_secrets.json")

  client_secrets = Google::APIClient::ClientSecrets.new(JSON.parse(client_secrets_json))

  auth_client = client_secrets.to_authorization
  auth_client.update!(
      :scope => Google::Apis::SheetsV4::AUTH_SPREADSHEETS, # 'https://www.googleapis.com/auth/drive.metadata.readonly',
      :redirect_uri => url('/oauth2callback'))
  if request['code'] == nil
    auth_uri = auth_client.authorization_uri.to_s
    redirect to(auth_uri)
  else
    auth_client.code = request['code']
    auth_client.fetch_access_token!
    auth_client.client_secret = nil
    session[:credentials] = auth_client.to_json
    redirect to('/')
  end
end