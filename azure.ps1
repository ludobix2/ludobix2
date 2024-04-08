# Variables
$resourceGroupName = "Nombre_del_Grupo_de_Recursos"
$location = "Ubicación"
$vmName = "Nombre_de_la_VM"
$vmSize = "Tamaño_de_VM" # Por ejemplo: "Standard_DS1_v2"
$adminUsername = "Nombre_de_Administrador"
$adminPassword = "Contraseña_del_Administrador"
$publicIpAddressName = "Nombre_de_IP_Pública"
$nicName = "Nombre_de_la_Tarjeta_de_Red"
$vnetName = "Nombre_de_la_Red_Virtual"
$vnetAddressPrefix = "Dirección_de_Red_Virtual"
$subnetName = "Nombre_del_Subred"
$subnetAddressPrefix = "Dirección_de_Subred"
$storageAccountName = "Nombre_de_la_Cuenta_de_Almacenamiento"
$osDiskName = "Nombre_del_Disco_del_Sistema_Operativo"
$imagePublisher = "Nombre_del_Proveedor_de_Imagen" # Por ejemplo: "MicrosoftWindowsServer"
$imageOffer = "Oferta_de_Imagen" # Por ejemplo: "WindowsServer"
$imageSKU = "SKU_de_Imagen" # Por ejemplo: "2019-Datacenter"
$publicRdpPort = 3389
$httpPort = 80
$httpsPort = 443

# Iniciar sesión en Azure
Connect-AzAccount

# Crear un nuevo grupo de recursos
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Crear una dirección IP pública
$publicIp = New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic

# Crear una interfaz de red
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId (New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix).Id -PublicIpAddressId $publicIp.Id

# Crear una VM
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential ($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzVMSourceImage -VM $vm -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSKU -Version latest
$vm = Set-AzVMOSDisk -VM $vm -Name $osDiskName -StorageAccountName $storageAccountName -CreateOption FromImage -Caching ReadWrite

# Crear la VM en Azure
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

# Configurar reglas del Grupo de Seguridad de Red
$securityGroupName = "Nombre_del_Grupo_de_Seguridad"
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $securityGroupName
$nsg | Set-AzNetworkSecurityRuleConfig -Name "RDP" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $publicRdpPort -Access Allow
$nsg | Set-AzNetworkSecurityRuleConfig -Name "HTTP" -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $httpPort -Access Allow
$nsg | Set-AzNetworkSecurityRuleConfig -Name "HTTPS" -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $httpsPort -Access Allow
$nsg | Set-AzNetworkSecurityRuleConfig -Name "SSL" -Protocol Tcp -Direction Inbound -Priority 1003 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443 -Access Allow
$nsg | Set-AzNetworkSecurityGroup

# Asociar el Grupo de Seguridad de Red a la interfaz de red
$nic | Set-AzNetworkInterface -NetworkSecurityGroup $nsg

# Imprimir la información de la VM
Write-Host "La VM $vmName se ha creado exitosamente."
Write-Host "Dirección IP pública: $($publicIp.IpAddress)"
Write-Host "Usuario Administrador: $adminUsername"
Write-Host "Contraseña del Administrador: $adminPassword"
