json.array!(@accounts) do |account|
  json.extract! account, :id, :name, :acc_type
  json.url account_url(account, format: :json)
end
