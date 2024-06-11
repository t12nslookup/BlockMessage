# Make the C:\SGS folder
C:
mkdir C:\SGS
cd C:\SGS

# expand the zip file
Expand-Archive 'C:\Users\jon_adams\OneDrive - SGS\Documents\BlockMessage.zip'

# move the files from the BlockMessage subdirectory to the current one
mv BlockMessage/* .
rmdir BlockMessage

# might need the following command running first:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

PS C:\SGS> .\SetFileAssociations.ps1
File associations updated successfully for all users.

PS C:\SGS> .\SetUserAssociations.ps1
File associations updated successfully for all users.