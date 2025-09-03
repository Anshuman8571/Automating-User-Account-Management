# Reads the users.csv file
$users=Import-Csv -Path 'C:\Developer\Automating-User-Account-Management\users.csv'

$logfile = "C:\Developer\Automating-User-Account-Management\user_management_logs.txt"

# Function to log Action
function Log-Action {
    param (
        [string]$message
    )
    $timestamp=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage="$timestamp - $message"
    Add-Content -Path $logfile -Value $logMessage
    Write-Output $logMessage
}

## Reiterate through each user present in the file
foreach ($user in $users) {
    $username=$user.Username
    $password=$user.Password
    $role=$user.Role
    $existingUser=Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    if ($existingUser) {
        <# Action to perform if the condition is true #>
        Log-Action "User '$username' exists. Updating the account."

        Set-LocalUser -Name $username -Password (ConvertTo-SecureString -AsPlainText $password -Force)

        # check if the particular user is the part of 'Administrator grp or not'
        $groupMember = Get-LocalGroupMember -Group "Administrators"

        if ($role -eq "Administrator") {
            <# Action to perform if the condition is true #>
            if($groupMember -notcontains $username){
                Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction SilentlyContinue
                Log-Action "The user named '$username' is added to the Administrator group."
            } else {
                Log-Action "'$username' is already a memver of the Administrator grp"
            }
        } elseif ($role -eq "Standard User") {
            <# Action when this condition is true #>
            if($groupMember -contains $username){
                Remove-LocalGroupMember -Group "Administrator" -Member $username
                Log-Action "Removed '$username' from the Administrator grp"
            } else {
                Log-Action "'$username' is not the member of the Administrator Group"
            }
        }
    } else {
        Log-Action "Creating a new User '$username'"
        # Creating a new User
        New-LocalUser -Name $username -Password (ConvertTo-SecureString -AsPlainText $password -Force) -FullName $username -Description "Created new User in your system using script."
        Log-Action "User '$username' Created successfully."

        # Assigning the roles now
        if ($role -eq "Administrator") {
            <# Action to perform if the condition is true #>
            Add-LocalGroupMember -Group "Administrators" -Member $username
            Log-Action "Added '$username' to the Administrator group."
        } elseif ($role -eq "Standard User") {
            <# Action when this condition is true #>
            Add-LocalGroupMember -Group "Users" -Member $username
            Log-Action "Added '$username' to the Users grp."
        }
    }

    # create home directory for the users and set the permissions
    $homeDir="C:\\Users\$username"
    if (-not (Test-Path $homeDir)) {
        <# Action to perform if the condition is true #>
        New-Item -Path $homeDir -ItemType Directory
        Log-Action "Created home directory for '$username' at '$homeDir'."
    }
    $acl=Get-Acl -Path $homeDir
    $permission="$username","FullControl","Allow"
    $accessRule=New-object System.Security.AccessControl.FileSystemAccessRule($permission)
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $homeDir -AclObject $acl
    Log-Action "Set full control permissions for $username on their home directory."

}