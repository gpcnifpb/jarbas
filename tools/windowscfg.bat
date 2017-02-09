:: Objetivos

:: Alterar PATH (Para adicionar comandos do vagrant e virtualbox)
setx path "%PATH%;D:\Hashicorp\Vagrant\bin;C:\Program Files\Oracle\virtualbox" /m

:: Definir VAGRANT_HOME (Para salvar as boxes no diretorio D:\GPCN\Boxes)
setx VAGRANT_HOME D:\GPCN\.vagrant.d\ /m

:: Definir VBOX_USER_HOME (Para salvar as VMs no diretorio D:\GPCN)
setx VBOX_USER_HOME D:\GPCN\.Virtualbox\ /m

:: Alterar machinefolder (Para salvar as VMS no diretorio D:\GPCN\VMs)
vboxmanage setproperty machinefolder D:\GPCN\VMs
