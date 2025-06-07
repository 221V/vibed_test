# dlang vibe.d simple web app

```
// vibe-d 0.10.2


// rm diet-ng 1.8.4 in vibe-http 1.2.2 -- https://github.com/221V/vibe-http/tree/rm_diet
"vibe-d": "~>0.9",
"mustache-d": "~>0.1.5"
->
"vibe-http": "~>1.2.2",
"vibe-stream": "~>1.1.1",
"mustache-d": "~>0.1.5"
->
"vibe-inet:crypto": "~>1.1.2",
"vibe-inet": "~>1.1.2",
"vibe-stream:tls": "~>1.1.1",
"vibe-stream": "~>1.1.1",
"vibe-inet:textfilter": "~>1.1.2",
"mustache-d": "~>0.1.5"


because gssapi_krb5 not supports static linking - use dynamics linking for it
ls /usr/lib/x86_64-linux-gnu/libgssapi_krb5*
/usr/lib/x86_64-linux-gnu/libgssapi_krb5.so@  /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2@  /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2.2

so delete -static
"dflags": ["-w", "-O", "-static"],

sudo apt update
sudo apt-get install libpq-dev libpq5 libldap2-dev libssl-dev libkrb5-dev

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

// https://github.com/repeatedly/mustache-d/blob/master/example/projects.d
// https://code.dlang.org/packages/mustache-d



$ cd <FOLDER_NAME>
$ make c


http://127.0.0.1:8080/


$ ldc2 -v
binary    /home/e/.dlang/bin/ldc2
version   1.39.0 (DMD v2.109.1, LLVM 18.1.6)
config    /home/e/.dlang/etc/ldc2.conf (x86_64-unknown-linux-gnu)
```

