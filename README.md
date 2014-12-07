THIS IS A POPULATOR!
it takes data from your gmail, then inputs that data into a database

You can choose to only search labeled emails, or all of them.

The data parsed is taken care of in the parse method.



The config file uses YAML (named 'config.yaml') and is in this format:
config:
  username: 'yourusername'
  password: 'yourpassword'
  label: 'label of emails to look up' (if 'none', then search entire mailbox)
  peek: 'true'/other (if true, emails parsed won't be labeled as read)
