# nsenter1

Convenience image to `nsenter` into namespaces for PID 1:

* mnt
* uts
* net
* ipc

To achieve the above with the basic alpine image you would enter:

    $ docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i sh
    / #

All this image does is save you from remembering all the `nsenter` options for the namespaces shown above,
but you still need to remember the docker container options.

There was an [outstanding issue](https://github.com/gliderlabs/docker-alpine/issues/359)
that prevented specifying the target pid with earlier versions of Alpine that necessitated the
creation of a custom image ([justincormack/nsenter1](https://github.com/justincormack/nsenter1))
with a program written in C to set things up correctly, although this is no longer needed.

With this image, you can simply run the following:

    $ docker run -it --rm --privileged --pid=host subfuzion/nsenter1
    / #

## So what is this good for

The `nsenter` command lets you to enter a shell in a running container (technically into the namespaces
that provide a container's isolation and limited access to system resources). This image allows
you to run a privileged container that runs nsenter for the process space running as pid 1 on your host.
How is this useful?

Well, this is useful when you are running a lightweight, container-optimized Linux distribution such as
[LinuxKit](https://blog.docker.com/2017/04/introducing-linuxkit-container-os-toolkit/).
Here is one simple example: say you want to teach a few people about Docker networking and you want to
show them how to inspect the default bridge network after starting two containers using `ip addr show`;
the problem is if you are demonstrating with Docker for Mac, for example, your containers are not running on
your host directly, but are running instead inside of a minimal Linux OS virtual machine specially built for
running containers, i.e., LinuxKit. But being a lightweight environment, LinuxKit isn't running `sshd`, so
how do you get access to a shell so you can run `nsenter` to inspect the namespaces for the process running as pid 1?

You could run the following:

    $ screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty

Docker for Mac does expose a screen session to attach to, but it's a bit less than ideal if you're not familiar
with screen. It's not a big deal, but it's not optimal and it's also very specific to Docker for Mac.

So the general solution using Docker is to run a container inside of the Linux VM that is mapped to
host process namespace (`--pid=host`) -- and just to be clear, `host` in this case refers to the Linux VM, not
your system host. Of course, this container will need to run as a privileged container (`--privileged`) to access
host namespaces. To be useful for interactive work, you will both STDIN and a TTY (`-it`). Finally, consider
naming your container to make identifying it easier in case you decide to detach and then reattach to it later
(of course, names need to be unique if you're going to run multiple containers at the same time).

So here is an example of this in action:


```
$ docker run -it --rm --privileged --pid=host --name=nsenter1 subfuzion/nsenter1
/ # ip a
256: vethb72bfa3@if255: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue master docker0 state UP
    link/ether 7a:41:32:02:63:7c brd ff:ff:ff:ff:ff:ff
    inet6 fe80::7841:32ff:fe02:637c/64 scope link
       valid_lft forever preferred_lft forever
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 brd 127.255.255.255 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 02:50:00:00:00:01 brd ff:ff:ff:ff:ff:ff
    inet 192.168.65.3/24 brd 192.168.65.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::49e8:1c10:4c64:c980/64 scope link
       valid_lft forever preferred_lft forever
...
```

Have fun!
 
