Various "one-line" commands for Koozali SME Server v9.2

Most of these were worked out in 2019, and worked then on a specific host.  They may need adjusting to work on any new host(s).

* List source IP from recent emails (yesterday or today)

  ```
  DAYS=1; find /home/e-smith/files/users/*/Maildir -name *$(config get SystemName)* -daystart -ctime  -$DAYS -print0 |while read -d $'\0' MSG; do IP=$(pcregrep -M "^Received: .*(\n.*){1,2}by $(config get DomainName).*" "$MSG" |perl -lne 'print $& if /(\d+\.){3}\d+/'); if [[ ! "$IP" =~ "(^127\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)" ]] && [ ! -z "$IP" ]; then echo -e "$IP\t$MSG"; fi; done
  ```

* Test input against DNSBL

  [rbl-recheck.sh](https://bugs.contribs.org/show_bug.cgi?id=9110)

  ```
  if [ -z "$RBLlist" ]; then RBLList=$(config getprop qpsmtpd RBLList | tr ":" "\n"); fi; DAYS=1; find /home/e-smith/files/users/*/Maildir -daystart -name *$(config get SystemName)* -ctime -$DAYS -print0 |while read -d $'\0' MSG; do IP=$(pcregrep -M "^Received: .*(\n.*){1,2}by $(config get DomainName).*" "$MSG" |perl -lne 'print $& if /(\d+\.){3}\d+/'); if [[ ! "$IP" =~ "(^127\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)" ]] && [ ! -z "$IP" ]; then IFS=. read IP1 IP2 IP3 IP4 <<< "$IP"; OKBL=""; for DNSBL in $RBLList; do ARESULT=$(dig +short "$IP4.$IP3.$IP2.$IP1.$DNSBL" |head -1); if [ "$ARESULT" ]; then break; else OKBL="$OKBL$DNSBL,"; fi; done; echo -e "$IP\t$ARESULT\t$DNSBL\t$OKBL\t$MSG"; fi; done
  ```

  ```
  export MAILHOST=my.smeserver.hostname
  DAYS=1; find /home/e-smith/files/users/*/Maildir -name *$(config get SystemName)* -ctime -$DAYS -exec pcregrep -M "^Received: .*\n.*by $MAILHOST.*" "{}" \|perl -lne 'print $& if /(\d+\.){3}\d+/'\; |grep -v "$(config get LocalIP)" |egrep "HELO|EHLO" |awk -F"[():]" '{ print $1 "\t" $7}'
  ```

* Count emails by disposition and Sender TLD for today and yesterday

  ```
  export LC_ALL=C;  mydate=$(date "+%Y-%m-%d")\|$(date -d "yesterday" "+%Y-%m-%d"); cat -v $(find /var/log/qpsmtpd -ctime -1 -type f) |tai64nlocal |egrep $mydate | grep -v ^# | awk -v date="$mydate" -v tots="                                   {{Total}}           " -F"[\t]" ' /logterse plugin/ {split($4,ss,"."); ssn=0; for (i in ss) { ssn++}; sendtld=tolower( ss[ssn]); sub(">","",sendtld); tld=sprintf("%-20s",sendtld); plugin=sprintf("%-35s",$6); plugint=sprintf("%35s%-20s",$6" ","{Total}");countem=plugin tld; count[countem]++; count[plugint]++; count[tots]++; }  END  {ORS=""; print "Subject: Email Disposition on " date "\nDenying plugin or \"queued\"         TLD                     Count   Pct\n=================================  ====================  =======  =====\n";  for (j in count) { pct=sprintf("%2.1f",(count[j]/count[tots])*100); j ~ /Total/ ?  myORS= " (" pct "%)\n": myORS="\n"; printf "%s%9s%s",j,count[j],myORS |"sort -b" } }'
  ```

* Block email from a host or network

  Adds entries to /var/service/qpsmtpd/config/hosts_allow with 'DENY_DISCONNECT' and today's date

  ```
  echo -n "Host or network to block: "; read HOST; echo "$HOST DENY_DISCONNECT $(date +%Y%m%d\ %H:%M) - Blocked by $(config get DomainName)" >> /var/service/qpsmtpd/config/hosts_allow; cat /var/service/qpsmtpd/config/hosts_allow; sv t qpsmtpd
  ```

* Remove blocked hosts older than 7 days

  Looks at the date added by the previous script and removes entries that were added over 7 days ago

  ```
  cd /var/service/qpsmtpd/config/; 'rm' -f hosts_allow.$(date +%Y%m%d); mv hosts_allow hosts_allow.$(date +%Y%m%d); awk '{if( $3>=strftime("%Y%m%d",systime()-(6*60*60*24))) print $0}' hosts_allow.$(date +%Y%m%d) > hosts_allow; cat hosts_allow; sv t qpsmtpd
  ```
* View dnsbl service acivity

  ```
  if [ -z $DAYS ]; then DAYS=1; fi; echo -n "Days of logfiles to scan [$DAYS]: "; read NEWDAYS; if [ $NEWDAYS ]; then DAYS=$NEWDAYS; fi; awk -F"[\t]" ' /logterse.*dnsbl/ { split($8,msg,"/"); svc=msg[3]; count[svc]++; count["Total"]++; }  END  { for (j in count) print count[j] "\t" j; }' $(find /var/log/qpsmtpd /var/log/sqpsmtpd -ctime -$DAYS -type f) |sort -nr
  ```

* Count disposition by plugin

  ```
  if [ -z $DAYS ]; then DAYS=1; fi; echo -n "Days of logfiles to scan [$DAYS]: "; read NEWDAYS; if [ $NEWDAYS ]; then DAYS=$NEWDAYS; fi; awk -F"[\t]" ' /logterse plugin/ { svc=$6; count[svc]++; count["Total"]++; }  END  { for (j in count) print count[j] "\t" j; }' $(find /var/log/qpsmtpd /var/log/sqpsmtpd -ctime -$DAYS -type f) |sort -nr
  ```

* Review email (qpsmtpd) disposition by TLD (eg ".faith", ".win", ".xyz", etc):

  ```
  echo -n "TLD to review: "; read TLD; qploggrep \.$TLD\> |tai64nlocal |awk '{print $1 " "  $2 "\t" $4 "\t" $5 "\t" $6 "\t" $7}'
  ```

* Count queued emails by Sender TLD

  ```
  if [ -z $DAYS ]; then DAYS=1; fi; echo -n "Days of logfiles to scan [$DAYS]: "; read NEWDAYS; if [ $NEWDAYS ]; then DAYS=$NEWDAYS; fi; awk -F"[\`\t]" ' /logterse plugin.*\(queue/ {split($5,ss,"."); ssn=0; for (i in ss) { ssn++}; sendtld=ss[ssn]; sub(">","",sendtld); count[sendtld]++; count["Total"]++; }  END  { for (j in count) print count[j] "\t" j; }' $(find /var/log/qpsmtpd /var/log/sqpsmtpd -ctime -$DAYS -type f) |sort -nr
  ```

* Count denied emails by Sender TLD

  ```
  if [ -z $DAYS ]; then DAYS=1; fi; echo -n "Days of logfiles to scan [$DAYS]: "; read NEWDAYS; if [ $NEWDAYS ]; then DAYS=$NEWDAYS; fi; awk -F"[\`\t]" ' /logterse plugin.*msg denied before queued/ {split($5,ss,"."); ssn=0; for (i in ss) { ssn++}; sendtld=ss[ssn]; sub(">","",sendtld); count[sendtld]++; count["Total"]++; }  END  { for (j in count) print count[j] "\t" j; }' $(find /var/log/qpsmtpd /var/log/sqpsmtpd -ctime -$DAYS -type f) |sort -nr
  ```

* Count emails by disposition ('queued' or blocking plugin) and Sender TLD 

  ```
  if [ -z $DAYS ]; then DAYS=1; fi; echo -n "Days of logfiles to scan [$DAYS]: "; read NEWDAYS; if [ $NEWDAYS ]; then DAYS=$NEWDAYS; fi; awk -F"[\t]" ' /logterse plugin/ {split($4,ss,"."); ssn=0; for (i in ss) { ssn++}; sendtld=ss[ssn]; sub(">","",sendtld); countem=$6"\t"sendtld; count[countem]++; count["Total"]++; }  END  { for (j in count) print j "\t" count[j] ; }' $(find /var/log/qpsmtpd /var/log/sqpsmtpd -ctime -$DAYS -type f) |sort 
  ```

* Count emails by disposition ('queued' or blocking plugin) and Sender TLD, but only for yesterday

  ```
  export LC_ALL=C; mydate=$(date -d "yesterday" "+%Y-%m-%d"); cat $(find /var/log/qpsmtpd -ctime -1 -type f) |tai64nlocal |grep $mydate | awk -v date="$mydate" -v tots="                                   {{Total}}           " -F"[\t]" ' /logterse plugin/ {split($4,ss,"."); ssn=0; for (i in ss) { ssn++}; sendtld=tolower( ss[ssn]); sub(">","",sendtld); tld=sprintf("%-20s",sendtld); plugin=sprintf("%-35s",$6); plugint=sprintf("%35s%-20s",$6" ","{Total}");countem=plugin tld; count[countem]++; count[plugint]++; count[tots]++; }  END  {ORS=""; print "Subject: Email Disposition on " date "\n\nMore info at http://etherpad.mmsionline.us/p/PMA_of_NOVA \n\nDenying plugin or \"queued\"         TLD                     Count   Pct\n=================================  ====================  =======  =====\n";  for (j in count) { pct=sprintf("%2.1f",(count[j]/count[tots])*100); j ~ /Total/ ?  myORS= " (" pct "%)\n": myORS="\n"; printf "%s%9s%s",j,count[j],myORS |"sort -b" } }'
  ```

* Count emails by disposition ('queued' or blocking plugin) and Sender TLD, but only for today

  ```
  export LC_ALL=C; mydate=$(date "+%Y-%m-%d"); cat $(find /var/log/qpsmtpd -daystart -ctime -1 -type f) |tai64nlocal |grep $mydate | awk -v date="$mydate" -v tots="                                   {{Total}}           " -F"[\t]" ' /logterse plugin/ {split($4,ss,"."); ssn=0; for (i in ss) { ssn++}; sendtld=tolower( ss[ssn]); sub(">","",sendtld); tld=sprintf("%-20s",sendtld); plugin=sprintf("%-35s",$6); plugint=sprintf("%35s%-20s",$6" ","{Total}");countem=plugin tld; count[countem]++; count[plugint]++; count[tots]++; }  END  {ORS=""; print "Subject: Email Disposition on " date "\n\nMore info at http://etherpad.mmsionline.us/p/PMA_of_NOVA \n\nDenying plugin or \"queued\"         TLD                     Count   Pct\n=================================  ====================  =======  =====\n";  for (j in count) { pct=sprintf("%2.1f",(count[j]/count[tots])*100); j ~ /Total/ ?  myORS= " (" pct "%)\n": myORS="\n"; printf "%s%9s%s",j,count[j],myORS |"sort -b" } }'
  ```
