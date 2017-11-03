Home-Assistant Build by [@onerealfunnyguy](https://twitter.com/onerealfunnyguy)

[Home Assistant](https://home-assistant.io/) configuration files (YAMLs)

Please :star: this repo and keep up to date on the progress!

Also visit my [blog](https://onerealfunnyguy.com).

![Screenshot of hive](https://onerealfunnyguy.com/screenshots/pic1.png)

This is my Home Assistant Configuration created with [Docker](https://home-assistant.io/docs/installation/docker/)

Home Assistant runs on 2 hand me down i5s with 8gbs of ram and an AMD with 12gbs of ram

**Gate:**
* SSL via [HAProxy](http://www.haproxy.org) & [letsencrypt](https://letsencrypt.org) - Free - cron auto renew on [PfSense Firewall](http://amzn.to/2Aj7XYH)

**Software Used on Host:**
* [debain](https://www.debian.org)
* [docker on debain](https://www.docker.com/docker-debian)
* [webmin](http://www.webmin.com)
* [cockpit](http://cockpit-project.org)

**Software in Docker :**
* [Home Assistant](https://home-assistant.io/) 2 - 1 main, 1 garden only
* [Dasher](https://github.com/maddox/dasher) with [Amazon Dash Buttons](http://amzn.to/2hBiO8f)
* [maria db](https://hub.docker.com/_/mariadb/)
* [Mosquitto MQTT](https://hub.docker.com/_/eclipse-mosquitto/)
* [python firetv](https://github.com/happyleavesaoc/python-firetv)
* [zoneminder](https://www.zoneminder.com)
* [plex](https://github.com/plexinc/pms-docker)
* [zabbix](https://www.zabbix.org/wiki/Dockerized_Zabbix)
* [influxdb](https://hub.docker.com/_/influxdb/)
* [grafana](https://hub.docker.com/r/grafana/grafana/)
* [transmission](https://hub.docker.com/r/linuxserver/transmission/)
* [unifi](https://hub.docker.com/r/linuxserver/unifi/)
* [glances](https://hub.docker.com/r/nicolargo/glances/)
* [sonarr](https://hub.docker.com/r/linuxserver/sonarr/)
* [sabnzbd](https://github.com/linuxserver/docker-sabnzbd)
* [transmission](https://github.com/linuxserver/docker-transmission)
* [stream2chromecast](https://hub.docker.com/r/onerealfunnyguy/stream2cast/)
* [sorttv](https://hub.docker.com/r/onerealfunnyguy/sorttv/)


**Devices I have :**
* [Ubiquiti Networks Unifi 802.11ac Pro](http://amzn.to/2zdBR0i)
* Lots of Android Devices running ipwebcam
* [Amazon Echo](http://amzn.to/2zb9EHa) and [DOT](http://amzn.to/2h1pg7V)
* [Amazon Echo Show](http://amzn.to/2zfLayF)
* [Amazon Echo Look](http://amzn.to/2zh7w2J)
* [Amazon Dash Buttons](http://amzn.to/2hBiO8f)
* [Amazon Dash Wand](http://amzn.to/2zgb5q6) - gen 1.
* [Amazon Fire TV](http://amzn.to/2zglRMS)
* [Amazon Fire Stick](http://amzn.to/2zhCHej)
* [Amazon Kindle FireHDx](http://amzn.to/2ze7WF5)
* [Phillips Hue Starter Kit](http://amzn.to/2zcvLNo)
* [White Lights](http://amzn.to/2zicSe3).
* [ChromeCast Audios](https://store.google.com/product/chromecast_audio)
* [Besign BE-TX Long Range Bluetooth Transmitter](http://amzn.to/2yt9T3q) so you think the Echo has tts.
* [Bluetooth Adapter USB](http://amzn.to/2xYYfJ2) bridged to HA for [MiFloras](https://www.aliexpress.com/item/English-Version-Xiaomi-Mi-Flora-Monitor-Digital-Grass-Flower-Care-Soil-Water-Light-Smart-Tester/32816679268.html?spm=2114.search0104.3.10.Z9MjwH&ws_ab_test=searchweb0_0,searchweb201602_3_10152_10065_10151_10130_10068_10344_10345_10547_10342_10546_10343_10340_10341_10548_10545_10541_10307_10060_10155_10154_10056_10055_10539_10537_10536_10059_10534_10533_100031_10103_10102_5670015_10142_10107_10324_5660015_10325_10084_10083_10178_10312_10313_10314_5650015_10550_10073_10551_10552_10553_10554_10557_10558-10343_10550,searchweb201603_30,ppcSwitch_5&btsid=af539bb1-dad9-4cc2-8c39-9dc4108a66ce&algo_expid=8d64c6a4-86c2-4508-82c6-7ecfd58cbdf9-1&algo_pvid=8d64c6a4-86c2-4508-82c6-7ecfd58cbdf9)
* [MiFloras](https://www.aliexpress.com/item/English-Version-Xiaomi-Mi-Flora-Monitor-Digital-Grass-Flower-Care-Soil-Water-Light-Smart-Tester/32816679268.html?spm=2114.search0104.3.10.Z9MjwH&ws_ab_test=searchweb0_0,searchweb201602_3_10152_10065_10151_10130_10068_10344_10345_10547_10342_10546_10343_10340_10341_10548_10545_10541_10307_10060_10155_10154_10056_10055_10539_10537_10536_10059_10534_10533_100031_10103_10102_5670015_10142_10107_10324_5660015_10325_10084_10083_10178_10312_10313_10314_5650015_10550_10073_10551_10552_10553_10554_10557_10558-10343_10550,searchweb201603_30,ppcSwitch_5&btsid=af539bb1-dad9-4cc2-8c39-9dc4108a66ce&algo_expid=8d64c6a4-86c2-4508-82c6-7ecfd58cbdf9-1&algo_pvid=8d64c6a4-86c2-4508-82c6-7ecfd58cbdf9)
* [ChromeCast](https://store.google.com/product/chromecast_2015)
* [RM2 Pro](http://amzn.to/2xYJXsf) RF / IR Blaster
* [NAS](http://amzn.to/2xX29SV)
* Emulated Hue pushes all Switches, Group, input_boolean, script and scene information to Alexa for Voice Control!

#Todo List
I'll start this section at [issues section](https://github.com/onerealfunnyguy/HA-Build/issues) on github.
Feel free to join the conversations there.

![Screenshot of Cave View](https://onerealfunnyguy.com/screenshots/pic2.png)
![Screenshot of Living Room View](https://onerealfunnyguy.com/screenshots/pic3.png)
![Screenshot of Cameras](https://onerealfunnyguy.com/screenshots/pic5.png)
![Screenshot of Network Monitor](https://onerealfunnyguy.com/screenshots/pic6.png)
![Screenshot of Garden HA](https://onerealfunnyguy.com/screenshots/pic10.pngg)
![Screenshot of More Garden HA](https://onerealfunnyguy.com/screenshots/pic13.png)
![Screenshot of CockPit Admin hive](https://onerealfunnyguy.com/screenshots/admin1.png)
![Screenshot of CockPit Admin shed](https://onerealfunnyguy.com/screenshots/admin2.png)


**All files are now being edited with [Atom](https://atom.io/).**

#Still have questions on my setup?
Message me on twitter : [@OneRealFunnyGuy](https://twitter.com/onerealfunnyguy)

Shout out to [@CCostan](https://twitter.com/ccostan) [HA-Config](https://github.com/CCOSTAN/Home-AssistantConfig)
without your hard work i would have never got around to a readme.  
