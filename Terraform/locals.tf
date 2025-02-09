locals {
  location = "francecentral"
  vms = {
    #Linux1 hosts :
    #PostgreSQL + 3 containers (API + php-app + php-producer)
    linux   = { name = "Linux1", size = "Standard_B2s", os = "linux" }
    #Linux2 hosts :
    #1 container (python-consumer)
    linux2  = { name = "Linux2", size = "Standard_B2s", os = "linux" }
    #Windows hosts :
    #A unique RabbitMQ instance
    windows = { name = "RabbitMQ", size = "Standard_B2s", os = "windows" }


  }
}
