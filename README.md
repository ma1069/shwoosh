# Self-Hosted WOorkSHpace

A tiny little guide explaining how I'm trying to work, hopefully without downsides, entirely relying on a remote mini-server. 

## Why

If you are a frontend/backend/full-stack web developer, you are certainly used to having products of your work being deployed to Linux servers.

But how much time do you spend, daily, having to deal with the perfect setup of your own, local development environment? How many times have you had to make compromises just because your computer is not 100% compatible with feature X that your product is currently using in production, making it impossible or extremely time-consuming to test stuff locally?

Maybe you replaced your Windows/Linux laptop with a new shiny Macbook, probably just because you had a budget for it and you wanted to work in a more luxurious way, reassuring your managers with something along the lines of: "It's Linux-based, the development efficiency will remain the same if not improve, and the machine will be much more stable than before"! And now you are silently enduring all the pain its "mac-iness" causes: depending on your stack, right now you are thinking about brew updates, docker/colima, permissions… it doesn't matter, you know perfectly what I'm writing about!

Or maybe that's not it! You are a nerd like me and fancy the idea of being able to do your job, for real, with the same efficiency and no compromises, through a smartphone connected to a monitor and a keyboard!

Either way, nowadays low-power mini PCs reached quite a remarkable level of performance, network speeds are always increasing, and the idea of developing through a separate device with server-like reliability features, WAY more similar to what production looks like, seemed to be quite intriguing, so I personally went for it. I started this readme as a way to take notes during my journey to be able to repeat it one day and will apply updates over time, hopefully, as long as the project keeps looking promising.

This is more a log than a guide, some of the steps might need some additional research. I'm not sure it will ever be worth making this guide more detailed, as tools evolve and instructions become stale… but please notify me about anything you struggle to understand, super happy to add more details then.

Personally, my goal will be to be able to develop by using three different stacks:
- python + uvicorn + postgresql
- php + nginx +mysql
- javascript + nodejs + vue

My aim is to rely on docker to work on containerized environments and use VS code for the editing part, as it provides a pretty complete browser-based version. This means most of the next steps and the tools I am going to suggest won't be dependent on this stack. Moreover, I'd like to keep some openings about how to integrate other code alternatives: not everybody likes coding from a browser.

Final disclaimer: please DON'T use this code at your workplace without being ready to own your outcomes. Some things you were used to doing in simpler ways will get slower and more complicated, and vice versa. Don't expect a perfect drop-in replacement of your current workplace, this is an ongoing experiment and there are going to be issues along the way!

## Tools:

- **A Linux box** (I used an AM06Pro, with a Ryzen5 5624U, 16GB ram, 512GB SSD for 300$. But I will surely try to move everything to a 100$ Raspberry PI 5, when it becomes available. Could we use a cloud instance instead? Maybe, but a 16GB instance is expensive. I just wanted to start with something powerful and eventually scale it down, so hopefully this will become feasible as well)
- **Debian** (at the time of writing, version 12, codename bookworm)
- **Tailscale** (cloud-based VPN, it's the trick we use to be able to access our home server from everywhere. It's free as long as you don't have too many devices under your control. This tool is AMAZING and it seems to be trusted worldwide but, If you are concerned about privacy and have any other cloud hosted space to install some scripts, check out Headscale, the FOSS self-hosted version of the same tool. It should be cool as well)
- **code-server**: browser-based version of VS code. There are very little downsides, as it supports terminal, debugging, plugins, and so on. I yet have to find his limits but for now this seems to be super cool

plus a lot of quality-of-life additional tools that are going to be particularly useful. This repository handles most of them through a docker-compose setup, this way you don't have to configure yourself, aside from some small required changes, and you can always finetune your setup by extending this repo or just reconfiguring the environment file. 

note: there is a nice repository listing a way wider list of tools you could use here https://github.com/mikeroyal/Self-Hosting-Guide. This article is just a selection of the tools I considered to be the most useful/promising ones.

## Setup

### Install Debian

This is the only moment you will need a monitor and a keyboard attached to the mini pc (optional, really, but I'm too lazy to guide you a through network install. Check some other guide online if you don't have a spare monitor to use for this): put this img into an usb pen and boot https://www.debian.org/distrib/netinst. 

Choose a custom install, disable every feature (especially UI packages), and leave the software selection page with just "SSH server" and "standard system utilities" installed. We are not going to need anything else, everything will come up afterward.

Then, detach everything and just connect to the device through SSH: you can put the monitor and keyboard away now. Uncertain how to get the server IP address, e.g. because you are too used to ubuntu commands? 
```
   $ ip addr
```

By default, Debian doesn't seem to have sudo, so we want to install it (totally optional, skip it if you don't like the idea), along with vim (because I like using arrow keys), and other dependencies we will need pretty soon.

```
  $ su -
  # apt install sudo vim curl git make
  # usermod -aG sudo <YOUR_USER_NAME>
```

Now just close your ssh session and reopen it, and you should be able to call any command through sudo.

The final thing to install, worth a separate section, is docker:

```
  $ sudo apt update
  $ sudo apt install ca-certificates curl gnupg
  $ sudo install -m 0755 -d /etc/apt/keyrings
  $ curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $ sudo chmod a+r /etc/apt/keyrings/docker.gpg
  $ echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  $ sudo apt update
  $ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  $ sudo groupadd docker
  $ sudo gpasswd -a $USER docker
```

Then reboot (if you don't like reboots, just restart the docker daemon and then log out and back in).

All lines apart from the last two are straight from https://docs.docker.com/engine/install/debian/. Please feel free to double-check that guide and change some lines if you think it's better. 

### Recommended QOL shell tools

**sysv-rc-conf**  Not really required for anything, but I found this guy quite useful:
```
  $ sudo apt install sysv-rc-conf
```

This is a super nice CLI to configure which daemon runs at which runlevel. I've personally used to shut down smbd and other pre-installed services I didn't plan to use on my machine, just to optimize resources and minimize open ports. You could already have it installed, or you might not like the idea, but I just wanted to mention it, it's so cool, I wish I found out about this guy earlier.

**zsh** Another opinionated choice, I like using this shell instead of the traditional bash: its case-insensitive autocomplete feature is super nice and its extensions are even better. In case you might share the love for this shell, installation is trivial, really:
```
  $ sudo apt install zsh
  $ chsh -s $(which zsh)
  $ sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**locale changes**: it might just be me, but I received some locale errors when launching certain commands. So I fixed those by adding this parameter in .bashrc (or .zshrc)
```
  export LC_ALL="en_US.UTF-8"
```

The errors I saw were 100% due to the ssh configuration of my client computer, so you might not need this at all, but I am attaching this here just for reference.

## Install Tailscale

There's not much to say here, just that it's hand down the best VPN-like solution I ever stumbled upon. Just go to the https://tailscale.com/ website and follow the instructions. You will be able to register multiple devices by running a specific install script on each of them: Tailscale will then assign a unique IP to each device, and you will always be able to access such devices through that IP from all other registered devices, regardless from the network you are in. After that, you will basically be able to forget about its existence! And this is just the tip of the iceberg, I highly recommend delving through Tailscale documentation to fall even more in love with this service!

These instructions might be obsolete, but in my case, I did install Tailscale through these commands:
```
  $ curl -fsSL https://tailscale.com/install.sh | sh
  $ sudo tailscale up
```

You could then play with Tailscale settings to fiddle with DNS and assign hostnames to each device: I've personally just opted to edit the etc/hosts file on my client to give a name to my remote machine.
Note: if you don't like the idea of relying on a free VPN-like service, please take a look at Headscale: it's the FOSS version of tailscale manager, that should allow creating a 100% self-hosted solution. In that case, however, it's your responsibility to make Headscale installation available from everywhere, through a public static IP address, or hosting it to a public domain somehow. I haven't been through that process, yet, so I don't know much more about it.

## Protect the server and make it easy to configure  -  Install Cockpit! 

In basically all the next steps, we will install new services that will attach themselves to different ports, and those ports will have to be exposed so that we can access them through Tailscale. Before digging deep in the fun part, let's talk a bit about the boring security aspects: when working locally, we usually safely ignore all these concerns, but in this case situation is a bit different! Our home WiFi router and Tailscale already give us quite a solid bit of protection, but this could be not enough.

So, what to do? Will we need to worry every time we decide to try and set up a new service, by identifying a different method to protect it? In this guide I went for a more general approach, that basically goes along these lines: I have decided to consider Tailscale network interface as "completely safe", and open every port there so that every new service I run will be available to my client. On the other hand, all the other network interfaces will have all ports closed (with the exception of the SSH port, just in case). This should theoretically allow me to work through all the next steps without worrying too much about security. Then, we will see… probably adding some sort of captive portal to protect that endpoint as well could be fun! 

For now, let's focus on protecting those interfaces! The nice part is that Debian already comes with `iptables`, so there isn't much to do aside from configuring it… but hey, it's 2023 and we are running loads of web-based services. So, why not use a web-based firewall configurator for that?

This investigation took a weird turn, as looking for a web-based firewall configurator I stumbled upon Cockpit (https://cockpit-project.org/) which does WAY more than that, as it provides a full administration panel for our tiny server. But that's even better! Now we have a "settings" page for our server, more powerful than any Linux settings UI has ever been! 

Setup instructions are here: https://cockpit-project.org/running.html#debian 
This is super trivial, as Cockpit is a Debian package, after all. The few changes suggested there are just to include backport updates, to get the last version possible of a few dependencies.

The only negative side of Cockpit is that it does not allow to configure `iptables` right away, but we first have to install `firewalld` (and manually enable Cockpit port in there): a bit of an extra work, but it's worth it, I swear!
```
  $ sudo apt install firewalld
  $ sudo firewall-cmd --add-port=9090/tcp
  $ sudo firewall-cmd --reload
```

### How to set up the firewall, after setup? 

- just go to your box address, at the *:9090 port;
- log in with the same credentials you use to open ssh
- click the "administrative access" button and input your password again (if you did install sudo, you might need a different solution otherwise)
- now go to the "networking" tab and click on "edit rules and zones", in the "firewall" area
- add a new zone, select "home", and select the Tailscale interface. Press "Add zone"
- this will open up just basic ports. Now click on "Add services", "Custom ports", and type "80–9999" for both tcp and udp. Give it a pretty ID and a pretty name if you like. These are the ports you most likely want to use when working, so there is no reason to be specific and come back here every 5 minutes… just open up everything (only on this network interface of course)
- finally, let's protect all the other ports: an easy way to do this is to add another zone, check the "external" box, and select the other network interfaces. This should only allow SSH and cockpit, on that interface, but I personally even manually disabled Cockpit itself, there.

**note**: Cockpit is a powerful admin tool, so it should make sense to protect it as we just did, but please, try not to lock you out completely from your box: what happens if Tailscale service is not available, for whatever reason (e.g. internet doesn't work)? I've personally protected my WiFi interface as mentioned before as, for now, my box is going to be connected through WiFi. But I've left the Cockpit port open on the ethernet interface, so that in case of an emergency, if ssh is not enough for whatever reason, I can still have access to everything just by connecting through a cable.

**note**: regardless of what you set on Cockpit, you will still have port 9090 opened to every network interface, thanks to the workaround command called at the beginning. Just reboot the computer to make those settings go away (and to make sure all other settings work as intended.

## Install code-server

This is the last tool we are going to set up "manually": for now I've decided to install vs code in its non-dockerized form, as it makes it easier to interact with the local environment and "drive" everything from there. In the future, this could change, but it would increase setup complexity and again I'm lazy, so it stays like that, for now! :)

At the time of writing, the setup guide is here https://coder.com/docs/code-server/latest/install#installsh and it's just this oneliner:
```
$ curl -fsSL https://code-server.dev/install.sh | sh
```

Now: before launching code-server, let's make sure we have control over the environment! By default, it's launched on port 8080, but that's such a common port… we are quite likely going to need that during development! So let's just edit the ~/.conf/code-server/config.yml file and set the `bind-addr` field to something else. I've chosen `0.0.0.0:9001` (removing 127.0.0.1 is important as this way you'll manage to make it available on Tailscale interface as well). It might be a nice moment to either set a useful password, or just set the authentication to none: this vs code instance is well protected anyways, no need to add further barriers to slow down development… or actually one can never feel protected enough, your call.

Then, just turn on the server permanently, through:
```
sudo systemctl enable --now code-server@$USER
```

This is just the initial setup, we still need to define a folder to store all code and to set up plugins. We will get there, but in the meantime, you can already check out your vs code instance on port 9001!

## Everything else

That's it, basically. Everything else is handled self-automatically by this repo. So you just have to: 
- clone this repository
- copy the SETTINGS.env.template to SETTINGS.env
- fill up required fields within SETTINGS.env, and eventually update the list of services you want to change
- set the boy up:
```
$ make up
```

But actually, WHAT are you turning on with this command?

### Portainer

I don't know you, but my development stacks are heavily based on docker containers, so I made this repo of development tools running the same container setup. This means we already have quite a few containers, and this number will likely explode. Terminal is the king here, but we might want to be able to monitor them accurately in an easy way as well, so we need a UI for that. 
The self-hosted community unanimously pushed me towards Portainer. They were SO right! 

For what concerns setup, just go to port 9003, ignore the self-signed certificate warning, and set up a username and a password (something easy, I haven't found a way to disable this, unfortunately). You will be welcomed by a wizard asking you to define an environment, but you can actually skip this for our use case: just click on "home" and press the "live connect" button in the "local environment". 
Click on "get started"

### Homepage

We are going to have SO many different tools to work with, and we might feel lost with all these port numbers. A nice way I've found to get around this issue is to configure Homepage, a pretty nice dashboard based on yaml configuration files. Upon setup it will create a .home.config folder in your home directory with some sample set-up files: if you followed along with my choices of port numbers until now you can find some other configuration files in the home.config folder you can copy from.

It's just a cool tool not to lose track of everything we set up, but mileage might vary... Homepage being the perfect fit for me doesn't mean it will be for you as well, really.

### Excalidraw

I'm addicted to this tool! It allows to draw super cute diagrams in an hand-drawn style.

Please note: as of today, there is no real advantage in self-hosting excalidraw rather than just going to excalidraw.com URL. So you might want to just skip this. I've kept it just for coherence

### Database GUI(s): DBGate and SQLChat

No more phpMyAdmin, I swear: it's a beautiful tool but I've had enough of it in my past decades.

For this reason, I've identified two possible alternatives that look fine:

- **dbgate** (https://github.com/dbgate/dbgate), a very promisingly powerful database client that should tick all your boxes in terms of features: on top of all features, its capability to run browser-based, that should allow us to do everything we might ever need.
- **sqlchat** (https://github.com/sqlchat/sqlchat): Are you particularly passionate about AI? This chatgpt-based database client promises to both provide a text-based interface to interrogate your data, as well as provide basic functionalities every db client gives. Will this actually help us to save some time? 
