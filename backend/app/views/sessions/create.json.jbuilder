json.status @status
json.error_message @error
json.data do
  json.user  do
    json.partial! 'users/user', user: @user
  end
  json.sid @sid
end
