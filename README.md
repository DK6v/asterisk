## Initial configuration

### To connect to the FreePBX Web UI
Open web browser and navigate to https://localhost/admin
Set the 'admin' password and then login to the FreePBX Administration page.

### Enable advanced settings
- Navigate to 'Settings'->'Advanced Settings'.
- Enable the 'Display Readonly Settings' and 'Override Readonly Settings' options in the 'Advanced Settings Details' section.
- Press the 'Submit' button to save your changes and then reload the page.

### Set the Asterisk Manager (AMI) server names.
- Navigate to 'Settings'->'Advanced Settings'.
- Change the 'Asterisk Manager Host' field to 'asterisk.server' in the 'Asterisk Manager' section.
- Press the 'Submit' and then the 'Apply Config' buttons.

### Set the  Remote CDR Database server names.
- Navigate to 'Settings'->'Advanced Settings'.
- Change the 'Remote CDR DB Host' field to 'asterisk.mysql' in the 'Remote CDR Database' section.
- Press the 'Submit' and then the 'Apply Config' buttons.
