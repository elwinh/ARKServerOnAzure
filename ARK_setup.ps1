# Clear the screen
CLS

# Change the settings below to reflect your settings:
$config_Subscription = 'Visual Studio Enterprise met MSDN'

## Global
$ResourceGroupName = "arkservers"
$Location = "WestEurope"

## Storage
$StorageName = "arkstorage01"
$StorageType = "Premium_LRS"

## Network
$InterfaceName = "ARKServerInterface01"
$Subnet1Name = "SubnetARK"
$VNetName = "VNetARK"
$VNetAddressPrefix = "10.1.0.0/16"
$VNetSubnetAddressPrefix = "10.1.0.0/24"

## Compute
$VMName = "ArkServer01"
$ComputerName = "ARKGameServer01"
$VMSize = "Standard_DS1"
$OSDiskName = $VMName + "OSDisk"

##########################
# Setup Azure PowerShell #
##########################

# Install the NuGet provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install the Azure Resource Manager modules from the PowerShell Gallery
Install-Module Azure       # Classic Azure 
Install-Module AzureRM     # The new portal with the new Resource Manager
Install-AzureRM

# Import AzureRM modules for the given version manifest in the AzureRM module
Import-AzureRM

# Import Azure Service Management module
Import-Module Azure

#####################################
# Connect to Azure and run our code #
#####################################

# Log in
Login-AzureRmAccount

# Get the Azure Resource Management Subscription:
Get-AzureRmSubscription –SubscriptionName $config_Subscription | Select-AzureRmSubscription

# Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

# Storage
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location
Set-AzureRmCurrentStorageAccount –ResourceGroupName $ResourceGroupName –StorageAccountName $StorageName

# Network
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static -Force
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig -Force
$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id -Force

# Compute

## Setup local VM object
$Credential = Get-Credential
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version "latest"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching ReadWrite -CreateOption FromImage
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
$VirtualMachine

