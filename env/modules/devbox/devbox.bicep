param location string
param devRgName string
param kvName string = 'jogardn-kv'
@secure()
param adminUsername string
@secure()
param adminPassword string
param tags object
param vTPM bool = true
param secureBoot bool = true
@description('MAA Endpoint to attest to.')
@allowed([
  'https://sharedcus.cus.attest.azure.net/'
  'https://sharedcae.cae.attest.azure.net/'
  'https://sharedeus2.eus2.attest.azure.net/'
  'https://shareduks.uks.attest.azure.net/'
  'https://sharedcac.cac.attest.azure.net/'
  'https://sharedukw.ukw.attest.azure.net/'
  'https://sharedneu.neu.attest.azure.net/'
  'https://sharedeus.eus.attest.azure.net/'
  'https://sharedeau.eau.attest.azure.net/'
  'https://sharedncus.ncus.attest.azure.net/'
  'https://sharedwus.wus.attest.azure.net/'
  'https://sharedweu.weu.attest.azure.net/'
  'https://sharedscus.scus.attest.azure.net/'
  'https://sharedsasia.sasia.attest.azure.net/'
  'https://sharedsau.sau.attest.azure.net/'
])
param maaEndpoint string = 'https://sharedeus2.eus2.attest.azure.net/'

var disableAlerts = 'false'
var ascReportingEndpoint = 'https://sharedeus2.eus2.attest.azure.net/'
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var useAlternateToken = 'false'



resource devResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: devRgName
}

resource devSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  scope: resourceGroup(devResourceGroup.name)
  name: 'dev-vnet/agents-subnet'
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'NI-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: devSubnet.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
  tags: tags
}

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'SG-01'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-3389-home-ip'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '192.168.1.0/24'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
  tags: tags
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'VM-01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: any('Standard_D8s_v5')
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-21h2-ent'
        version: 'latest'
      }
      osDisk: {
        name: 'DS-01'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: secureBoot
        vTpmEnabled: vTPM
      }
      securityType: 'TrustedLaunch'
    }
    osProfile: {
      computerName: 'VM-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          enableHotpatching: false
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client'
  }
  tags: tags
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if (vTPM && secureBoot) {
  parent: virtualMachine
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      AttestationEndpointCfg: {
        maaEndpoint: maaEndpoint
        maaTenantName: maaTenantName
        ascReportingEndpoint: ascReportingEndpoint
        useAlternateToken: useAlternateToken
        disableAlerts: disableAlerts
      }
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: resourceGroup(devResourceGroup.name)
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${kvName}/vm-deployment'
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: virtualMachine.identity.principalId
        permissions: {
          keys: [
            'list'
            'get'
            'decrypt'
            'encrypt'
            'unwrapKey'
            'wrapKey'
          ]
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
  }
}

resource diskEncryption 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: virtualMachine
  name: 'diskEncryption'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: 'https://${keyVault.name}${environment().suffixes.keyvaultDns}'
      KeyVaultResourceId: keyVault.id
      VolumeType: 'All'
    }
  }
}
