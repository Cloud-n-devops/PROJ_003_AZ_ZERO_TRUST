-- Create a user for the User-Assigned Identity
CREATE USER [id-laravel-app] FROM EXTERNAL PROVIDER;

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER [id-laravel-app];
ALTER ROLE db_datawriter ADD MEMBER [id-laravel-app];
ALTER ROLE db_ddladmin ADD MEMBER [id-laravel-app]; -- Required for 'php artisan migrate'


<!-- Don't guess the GUIDs. Use the Azure CLI to find the exact ID for any policy name: -->

az policy definition list --query "[?displayName=='Allowed locations'].{Name:name,Id:id}" --output table