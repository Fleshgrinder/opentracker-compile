# opentracker
Shell script for compiling latest [opentracker](https://erdgeist.org/arts/software/opentracker/) from source.

## Install
```shell
cd /usr/local/src
git clone https://github.com/Fleshgrinder/opentracker-compile.git
sh opentracker-compile/compile.sh
```

## Usge
A [Linux Standard Base (LSB)](http://www.linuxfoundation.org/collaborate/workgroups/lsb) compliant [SysVinit]
(http://freecode.com/projects/sysvinit) script is included and automatically installed in `/etc/init.d` for you. It 
also adds the tracker to the start-up of your server (if you do not want that, issue `update-rc.d opentracker remove` 
after installation).

You can control the tracker via the `service` command or by directly invoking the shell script in `/etc/init.d`; what 
you like best. Your shell will have auto-completion for the various keywords that are available, for instance if you 
type `service opentracker res` just hit tab for auto-completion.

```shell
service opentracker force-reload
service opentracker restart
service opentracker start
service opentracker status
service opentracker stop
```

## License
> This is free and unencumbered software released into the public domain.
>
> For more information, please refer to <http://unlicense.org>
