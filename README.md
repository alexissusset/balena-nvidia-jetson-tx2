# Soracom internal NVIDIA Jetson TX2 Resin project  

## Description  
This project leverages resin.io NVIDIA Jetson TX2 boards and multi-container support.  
All major ML frameworks have been incorporated into one project so as to facilitate development of various projects  

## Deployment  
If you would like to use Soracom's existing resin.io TX2 project, you can ask access from Alexis  
You can otherwise create your own resin.io project by choosing the NVIDIA Jetson TX2 board  
  
Once you have your project running, you will have to create a SD card with TX2 image, this card will only be used to provision the TX2 board (be careful, it will erase all existing data on your TX2). You can find more details about the procedure on Resin website:  
https://docs.resin.io/learn/getting-started/jetson-tx2/python/
  
Now that your TX2 has been provisioned, it will appear in your Resin App devices list  
  
## How to use  
This Resin image comes with multiple containers, each one of them incorporating a different Machine Learning framework. As resin CLI doesn't yet support multiple containers ssh access, the best way to connect is to use the `resin ssh -s` command which will give you access to the base ResinOS.  
Once connected, you can then look at your containers using the `balena container list` command
```
TypeLex@TypeLexMacBook:~$ resin ssh -s
? Select a device Santa Clara (Alexis) (fa43fb6)
Connecting to: fa43fb64c58997cd7ecc4fa00e18be05
=============================================================
    Welcome to ResinOS
=============================================================
root@fa43fb6:~# balena container list
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                            PORTS               NAMES
d478249b48d4        9afd042eb42b                       "/bin/sh -c '/DIGI..."   23 hours ago        Up 3 minutes                      5001/tcp            digits_274288_488701
62fcc8c8a840        737fd2dbf9a2                       "/bin/sh -c 'exec ..."   24 hours ago        Up 3 minutes                                          tensorrt_274287_488701
ae8bf66410e2        650afb8dc20d                       "/bin/sh -c 'exec ..."   24 hours ago        Up 3 minutes                                          tensorflow_274289_488701
bfdf59d7c8a4        e8e8a885f732                       "/bin/sh -c 'exec ..."   24 hours ago        Up 3 minutes                                          opencv4tegra_274293_488701
f06873a3db9c        475fd0cec479                       "/bin/sh -c 'exec ..."   24 hours ago        Up 3 minutes                                          chainer_274290_488701
2304f6e0ce8e        a60082d5aff6                       "/bin/sh -c 'exec ..."   24 hours ago        Up 3 minutes                                          cudabase_274286_488701
e220f82c4809        5987a7ef45c9                       "/bin/sh -c 'exec ..."   24 hours ago        Up 3 minutes                                          ubuntu_274291_488701
03590eb9da00        f15b132231cf                       "/usr/bin/entry.sh..."   3 days ago          Restarting (0) 49 seconds ago                         connectivity_274285_488701
4cc452ae1e1a        resin/aarch64-supervisor:v7.1.18   "/sbin/init"             6 weeks ago         Up 3 minutes (health: starting)                       resin_supervisor
```
And now you can start a shell in the container you want by using the `balena exec -it "<container name>" bash` command
```
root@fa43fb6:~# balena exec -it "digits_274288_488701" bash
root@d478249b48d4:/#
```

## Available containers
As a note, some of the bellow containers have been commented out as the base NVIDIA JETSON TX2 is limited to 32GB of eMMC storage, each container being ~6GB in size, we cannot run all bellow containers at the same time on a base TX2 (or TX1 which has 16GB eMMC) 
You can enable / disable containers by editing the docker-compose.yml file and running the `git push resin master` command  

### NVIDIA cafee
Nvidia's edition of caffee framework, v0.17 is compiled and deployed during container built.  
This container also comes with CUDA, TensorRT and OpenCV4Tegra  
More information can be found at https://github.com/NVIDIA/caffe

### Chainer
Chainer framework together with python modules, this includes numpy and chainercv which ensures that chainer runs optimized with CUDA drivers.  
This container also comes with CUDA, TensorRT and OpenCV4Tegra  
More information can be found at https://docs.chainer.org/en/stable/

## Connectivity
This is a connectivity management container, it runs Modem Manager and Python Network Manager module, ensuring that Soracom connection is added on first boot and keeping the device connected at all times (it will keep rebooting the device if there is no connectivity).  
As Modem Manager is installed and as this container has full access to hardware, you can also use it to run AT commands.  
Additionally to base functionalities, the following settings can be configured using Resin Environment variables:  
* CELLULAR_ONLY: This option disables WiFi and Ethernet to ensure that the device solely uses Cellular connection  
* CONSOLE_LOGGING: Set to 1 in order to get application logs in Resin.io device console, logs are always written to /data/soracom.log, keep if off in order to save on Cellular based bandwidth  
* SCAN_OPERATORS: Set to 1 in order to scan available operators  
* OPERATOR_ID: Set to your preferred Operator ID and your modem will check if it's available, try to switch to it, reboot the host to connect back to an available operator if there's an error  
* SSH_PASSWD: Sets an ssh root password and starts openssh-server
  
It also incorporates log-rotate and openssh-server mainly to show what can be done within a Resin container  

# Running AT commands
Through ModemManager package, you can run AT commands on your Cellular modem.

To do so, we've set the following variable in our bashrc configuration which enables mmcli and python-networkmanager to communicate with ResinOS DBUS:  

`export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket`

With this in place, you can connect to resin remote Terminal (we recommend resin CLI with `resin ssh` command) and run AT commands as follow:

`mmcli -m 0 --command=ATCOMMAND`

## CUDA Base
Base container with CUDA drivers, generally used to test installs and updates of frameworks before updating Dockerfile  
This container also comes with TensorRT  
More information can be found at https://developer.nvidia.com/about-cuda

## NVIDIA DIGITS
Nvidia DIGITS server which can be used to train Machine Learning / Machine Vision models (Deep Learning GPU Training System)  
This container also comes with CUDA, TensorRT and OpenCV4Tegra  
More information can be found at https://github.com/NVIDIA/DIGITS  

## Dusty Jetson Inference
Dusty Jetson Inference is a demonstration Machine Vision Application that can be used to recognise objects in both images and videos  
This container also comes with CUDA, TensorRT and OpenCV4Tegra 
More information can be found at https://github.com/dusty-nv/jetson-inference

## OpenCV for Tegra
Nvidia Jetson optimised version of OpenCV, a common framework used for Machine Vision tasks  
To be useful, this container likely needs other tools installed such as for example doxygen  
This container also comes with CUDA and TensorRT 
More information can be found at https://opencv.org  

## Resin Base
Basic Resin TX container with Phyton 3 pre-installed  
No CUDA driver installed so mainly used as a base for testing optimized container deployments  

## Tensor Flow
Jetson optimised Tensor Flow container, the popular Google Machine Learning Framework  
This container also comes with CUDA and TensorRT 
More information can be found at https://www.tensorflow.org

## NVIDIA TensorRT
Base container with Jetson optimised TensorRT, same as OpenCV container so mainly here as an example  
This container also comes with CUDA and OpenCV 
More information can be found at https://developer.nvidia.com/tensorrt  

## Ubuntu
Basic Ubuntu aarch64 container, mainly for testing end-to-end installations as nothing else is installed but base Ubuntu Docker distribution  