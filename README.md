# dlang vibe.d simple web app

```
// vibe-d 0.10.2

// "diet-ng" is an optional dependency of vibe.d that is chosen by default - to avoid that, remove the "diet-ng" entry from dub.selections.json.
// https://github.com/vibe-d/vibe.d/blob/master/CHANGELOG.md


sudo apt-get install libevent-dev
sudo apt-get install libmemcached-dev
// libmemcached-dev:amd64 (1.1.4-1+ubuntu22.04.1+deb.sury.org+1)
sudo apt-get install memcached
// memcached (1.6.14-1ubuntu0.1)
// /lib/systemd/system/memcached.service
// sudo systemctl status memcached.service
// sudo vim /etc/memcached.conf

// https://habr.com/ru/articles/108274/
// https://github.com/TiberiuGal/memcached4d/blob/master/source/app.d
// https://github.com/221V/memcached4d  -- fixed but with vibe-d




$ cd <FOLDER_NAME>
$ make c


http://127.0.0.1:8080/


$ ldc2 -v
binary    /home/e/.dlang/bin/ldc2
version   1.39.0 (DMD v2.109.1, LLVM 18.1.6)
config    /home/e/.dlang/etc/ldc2.conf (x86_64-unknown-linux-gnu)
```

