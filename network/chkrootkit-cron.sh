#!/bin/bash

# cleanup
/bin/rm -rf /tmp/chkrootkit-cron_mail.txt

# mail config
/bin/echo -e "to:me@matthewtraughber.com" > /tmp/chkrootkit-cron_mail.txt
/bin/echo -e "from:chkrootkit@hub" >> /tmp/chkrootkit-cron_mail.txt
/bin/echo -e "subject:Chkrootkit for HUB" >> /tmp/chkrootkit-cron_mail.txt

# execute chkrootkit
/usr/sbin/chkrootkit -q &>> /tmp/chkrootkit-cron_mail.txt

# send mail
/usr/sbin/sendmail -vt < /tmp/chkrootkit-cron_mail.txt


