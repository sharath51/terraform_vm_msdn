resource "azurerm_resource_group" "rg" {
  name     = "myrg"
  location = "South India"
}

resource "azurerm_virtual_network" "myvnet" {
  name                = "myvnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "mysubnet" {
  name                 = "mysubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["10.0.1.0/24"]
} 

resource "azurerm_public_ip" "public_ip" {
  name                = "public_ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  domain_name_label   = "sharath"
}

resource "azurerm_network_interface" "vnic" {
  name                = "vnic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mysubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "myvm" {
  name                = "myvm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  admin_password      = "Password1234!@"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vnic.id,
  ]

  os_disk {

    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  
  provisioner "remote-exec" {

  inline= [
    "sudo apt update",
    "sudo apt upgrade -y",
    "sudo apt install -y default-jdk",
    "java -version",
    "sudo apt-get install -y apache2",
    "sudo apt-get install -y tomcat9.0",
    "sudo apt-get install -y libapache2-mod-jk",
  ]
  connection{
    type = "ssh"
    host = azurerm_public_ip.public_ip.fqdn
    user = "azureuser"
    password = "Password1234!@"
  }
}
}

resource "azurerm_network_security_group" "mynsg" {
  name                = "MyTestGroup-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 security_rule {
    name                       = "port-80"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "port-8080"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}


resource "azurerm_network_interface_security_group_association" "nsg_as" {
  network_interface_id      = azurerm_network_interface.vnic.id
  network_security_group_id = azurerm_network_security_group.mynsg.id
}

locals {
  number_of_disks = 2
}

resource "azurerm_managed_disk" "mydisk" {
  count                = local.number_of_disks
  name                 = "mydisk-${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
}

resource "azurerm_virtual_machine_data_disk_attachment" "mydiskattach" {
  count              = local.number_of_disks 
  managed_disk_id    = azurerm_managed_disk.mydisk.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.myvm.id
  lun                = "${count.index}"
  caching            = "ReadWrite"
}