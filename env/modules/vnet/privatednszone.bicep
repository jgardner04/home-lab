param privateDNSZoneName string
param tags object

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  tags: tags
  properties: {
    
  }
}

output privateDNSZoneName string = privateDNSZone.name
output privateDNSZoneId string = privateDNSZone.id
