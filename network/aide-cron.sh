#!/bin/bash

# cleanup
/bin/rm -rf /tmp/aide-cron_mail.txt

# mail config
/bin/echo -e "to:me@matthewtraughber.com" > /tmp/aide-cron_mail.txt
/bin/echo -e "from:aide@hub" >> /tmp/aide-cron_mail.txt
/bin/echo -e "subject:Aide for HUB" >> /tmp/aide-cron_mail.txt

# execute aide
/usr/sbin/aide --check &>> /tmp/aide-cron_mail.txt

# send mail
/usr/sbin/sendmail -vt < /tmp/aide-cron_mail.txt
