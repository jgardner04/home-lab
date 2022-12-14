targetScope = 'subscription'

resource hubrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${basename}-hub-rg'
  location: location
  tags: tags
}




param location string
var basename = 'home-lab'
var owner = 'jogardn'
var tags = {
  owner: owner
  purpose: 'home-lab'
}

